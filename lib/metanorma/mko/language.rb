# frozen_string_literal: true

module Metanorma
  module Mko
    # Language resolution for knowledge objects (#53 item 3),
    # consumer-side of metanorma/metanorma-standoc#1243: standoc's
    # converter does not emit element-level xml:lang and the models do
    # not map it, so producer markup today cannot tell a translated
    # annex from the body. Resolution follows W3C XML §2.12 — xml:lang
    # is inheritable, an element's effective language is its nearest
    # ancestor-or-self xml:lang — extended with an honest fallback
    # chain for corpora whose markup carries no language at all:
    #
    #   1. "markup"    — nearest ancestor-or-self xml:lang. Element-
    #                    level attributes win automatically the day
    #                    standoc#1243 lands; a root xml:lang covers
    #                    every descendant until then.
    #   2. "heuristic" — stopword-ratio langid over the element's own
    #                    text (first SAMPLE_WORDS words; en/fr/es/de —
    #                    the same heuristic the RAG consumer adopts).
    #                    Fires only when NO xml:lang is in scope; an
    #                    inconclusive sample scores nil, never an en
    #                    bias. This is what tags a French terminology
    #                    annex inside an EN edition as fr.
    #   3. "default"   — the document's declared language (the bibdata
    #                    language, or the caller's document default).
    #   4. "fallback"  — DEFAULT_LANG with an explicit "fallback"
    #                    source: nothing declared, nothing detected.
    #
    # Every Resolution carries its provenance in source — consumers
    # can always tell markup-tagged language from a detected one.
    module Language
      # lang: a BCP 47 tag as declared ("en", "fr", ...); source:
      # "markup" | "heuristic" | "default" | "fallback".
      Resolution = Struct.new(:lang, :source, keyword_init: true)

      # Assumed only when nothing is declared and detection fails —
      # always reported with source "fallback", never silently.
      DEFAULT_LANG = "en"

      # The langid sample: the consumer contract is the first ~200
      # words of the element's own text.
      SAMPLE_WORDS = 200

      # Honesty guards: below MIN_WORDS sampled words or MIN_HITS
      # stopword hits there is no evidence — detect returns nil and
      # the precedence chain falls through instead of guessing.
      MIN_WORDS = 10
      MIN_HITS = 3

      # High-frequency function words per language (en/fr/es/de — the
      # consumer's coverage need). Flat frequency lists, no weighting:
      # every language scores over the same sample, so raw hit counts
      # are the ratios. Collisions ("la" is fr+es) wash out over a
      # real sample; the French single letters come from elision
      # splits (l'annexe -> "l"), which EN/DE/ES prose never yields.
      STOPWORDS = {
        "en" => %w[
          the of and to in is are that for with as this be on by at from
          or an not it its shall should must may will can which
        ],
        "fr" => %w[
          le la les des de du un une et est sont dans pour avec sur au
          aux par pas plus qui que ce cet cette ces être avoir selon
          doit doivent entre comme tout toute tous l d qu
        ],
        "es" => %w[
          el la los las de del un una es son en para con por que no más
          como se su sus al lo este esta estos estas y debe deben según
          entre también sobre ser está están
        ],
        "de" => %w[
          der die das den dem des und ist in im zu mit für auf von ein
          eine einer einem einen nicht sind oder bei nach über unter
          soll sollen müssen kann können wird werden auch als durch
        ],
      }.freeze

      XML_NS = "http://www.w3.org/XML/1998/namespace"

      class << self
        # The element-level machine. own: the element's own xml:lang
        # (nil where models don't map it). inherited: the enclosing
        # scope's Resolution (the nearest ancestor, already resolved).
        # default: the document-level Resolution (or a bare tag).
        def resolve(own: nil, text: nil, inherited: nil, default: nil)
          own = normalize(own)
          return Resolution.new(lang: own, source: "markup") if own
          # xml:lang in scope: the nearest ancestor's markup stands and
          # the heuristic stays off (W3C §2.12).
          return inherited if inherited&.source == "markup"

          detected = detect(text)
          return Resolution.new(lang: detected, source: "heuristic") if detected

          inherited || coerce(default) || fallback_resolution
        end

        # The document-level machine: the root xml:lang when carried,
        # else the declared document language (bibdata), else
        # detection over the document's own text, else the fallback.
        def document(markup: nil, declared: nil, text: nil)
          markup = normalize(markup)
          return Resolution.new(lang: markup, source: "markup") if markup

          declared = normalize(declared)
          return Resolution.new(lang: declared, source: "default") if declared

          detected = detect(text)
          return Resolution.new(lang: detected, source: "heuristic") if detected

          fallback_resolution
        end

        # XML side (Nokogiri node): full §2.12 nearest
        # ancestor-or-self over the live tree, then the element's own
        # text, then the document default, then the fallback.
        def for_node(node, default: nil)
          markup = [node, *node.ancestors].filter_map do |n|
            xml_lang_of(n)
          end.first
          return Resolution.new(lang: markup, source: "markup") if markup

          detected = detect(node.text)
          return Resolution.new(lang: detected, source: "heuristic") if detected

          coerce(default) || fallback_resolution
        end

        # XML side, document level: the root element's xml:lang, the
        # declared language, the document's own text, the fallback.
        def for_document(root, declared: nil)
          document(markup: xml_lang_of(root), declared: declared,
                   text: root.text)
        end

        # Stopword-ratio langid over the first SAMPLE_WORDS words of
        # text. Honest scoring: nil when the sample is too small, has
        # too few hits, or ties — never a default-to-en guess.
        def detect(text)
          words = text.to_s.downcase.gsub(/['’]/, " ")
            .scan(/[[:alpha:]]+/).first(SAMPLE_WORDS)
          return nil if words.size < MIN_WORDS

          scores = STOPWORDS.transform_values do |list|
            words.count { |word| list.include?(word) }
          end
          lang, hits = scores.max_by { |_, n| n }
          return nil if hits < MIN_HITS
          return nil if scores.any? { |l, n| l != lang && n == hits }

          lang
        end

        # A tag worth believing: stripped, downcased (BCP 47 tags are
        # case-insensitive); "" and "und" carry no information (XML
        # §2.12), so inheritance keeps walking.
        def normalize(tag)
          tag = tag.to_s.strip.downcase
          tag.empty? || tag == "und" ? nil : tag
        end

        private

        def xml_lang_of(node)
          attr = node.attribute_with_ns("lang", XML_NS)
          return normalize(attr.value) if attr

          # namespace-stripped trees keep a literal "xml:lang" name
          normalize(node["xml:lang"])
        rescue NoMethodError
          nil
        end

        def coerce(value)
          return value if value.is_a?(Resolution)

          tag = normalize(value)
          tag && Resolution.new(lang: tag, source: "default")
        end

        # The explicit last resort: undeclared and undetectable.
        # source "fallback" says so — never a silent en.
        def fallback_resolution
          Resolution.new(lang: DEFAULT_LANG, source: "fallback")
        end
      end
    end
  end
end
