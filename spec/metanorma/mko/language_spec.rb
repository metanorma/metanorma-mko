# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

RSpec.describe Metanorma::Mko::Language do
  # Realistic standards prose, one per covered language. Each clears
  # the honesty guards (>= MIN_WORDS words, >= MIN_HITS stopword hits)
  # on its own language alone.
  let(:en_text) do
    "This document specifies the metrological and technical " \
      "requirements that weighing instruments shall satisfy. For the " \
      "purposes of this document, the terms and definitions given in " \
      "the following apply. The requirements of this clause are " \
      "normative and shall be verified by the tests that are " \
      "described in the annex."
  end
  let(:fr_text) do
    "Le présent document spécifie les exigences métrologiques et " \
      "techniques auxquelles les instruments de pesage doivent " \
      "satisfaire. Pour les besoins du présent document, les termes " \
      "et définitions suivants s'appliquent. Les définitions données " \
      "dans la présente section sont conformes au Vocabulaire " \
      "international de métrologie."
  end
  let(:es_text) do
    "El presente documento especifica los requisitos que se deben " \
      "aplicar para la evaluación de la conformidad de los " \
      "instrumentos de pesaje. Las definiciones que se indican en " \
      "esta sección son las que se aplican en el ámbito de la " \
      "metrología legal."
  end
  let(:de_text) do
    "Die vorliegende Norm legt die Anforderungen an die Prüfung von " \
      "Waagen fest. Die Messungen sind unter den Bedingungen " \
      "durchzuführen, die in den Abschnitten der Norm beschrieben " \
      "werden. Für die Kalibrierung müssen die Instrumente den " \
      "Anforderungen entsprechen."
  end

  def xml_node(xml, xpath)
    Nokogiri::XML(xml).at_xpath(xpath)
  end

  describe ".detect" do
    it "scores each covered language honestly" do
      expect(described_class.detect(en_text)).to eq("en")
      expect(described_class.detect(fr_text)).to eq("fr")
      expect(described_class.detect(es_text)).to eq("es")
      expect(described_class.detect(de_text)).to eq("de")
    end

    it "stays silent below the minimum sample (no en bias)" do
      expect(described_class.detect("Mass: 5 kg")).to be_nil
      expect(described_class.detect(nil)).to be_nil
    end

    it "stays silent on text with no stopword signal" do
      expect(described_class.detect("α β γ δ ε ζ η θ ι κ λ μ ν ξ ο π")).to be_nil
    end

    it "stays silent on a tie rather than picking a winner" do
      # "the" scores en, "und" scores de — equal hits, no honest call
      expect(described_class.detect("the und " * 6)).to be_nil
    end

    it "samples only the first SAMPLE_WORDS words" do
      # 200 en words followed by French: the sample window decides
      text = "#{en_text} #{en_text} #{fr_text}"
      expect(described_class.detect(text)).to eq("en")
    end
  end

  describe ".normalize" do
    it "strips and downcases declared tags (BCP 47 is case-insensitive)" do
      expect(described_class.normalize("  FR ")).to eq("fr")
    end

    it "treats empty and und as absent (XML §2.12: no information)" do
      expect(described_class.normalize("")).to be_nil
      expect(described_class.normalize(nil)).to be_nil
      expect(described_class.normalize("und")).to be_nil
    end
  end

  describe ".resolve (the element-level machine)" do
    let(:en_default) do
      described_class::Resolution.new(lang: "en", source: "default")
    end

    it "lets the element's own markup win over inherited scope" do
      res = described_class.resolve(own: "fr", text: en_text,
                                    inherited: en_default)
      expect(res).to eq(described_class::Resolution.new(lang: "fr",
                                                        source: "markup"))
    end

    it "keeps ancestor markup authoritative — the heuristic stays off " \
       "when xml:lang is in scope (the standoc#1243 forward path)" do
      inherited = described_class::Resolution.new(lang: "en",
                                                  source: "markup")
      res = described_class.resolve(text: fr_text, inherited: inherited)
      expect(res.lang).to eq("en")
      expect(res.source).to eq("markup")
    end

    it "detects from the element's own text when no xml:lang is in " \
       "scope — the French annex inside an EN document" do
      res = described_class.resolve(text: fr_text, default: en_default)
      expect(res.lang).to eq("fr")
      expect(res.source).to eq("heuristic")
    end

    it "inherits the enclosing scope when detection is inconclusive" do
      annex = described_class::Resolution.new(lang: "fr",
                                              source: "heuristic")
      res = described_class.resolve(text: "5.2.1", inherited: annex)
      expect(res).to eq(annex)
    end

    it "falls to the document default when nothing else resolves" do
      res = described_class.resolve(text: "Table 1", default: "en")
      expect(res.lang).to eq("en")
      expect(res.source).to eq("default")
    end

    it "ends at the explicit fallback when nothing is declared" do
      res = described_class.resolve(text: "Table 1")
      expect(res.lang).to eq(described_class::DEFAULT_LANG)
      expect(res.source).to eq("fallback")
    end
  end

  describe ".for_node (XML side, W3C §2.12)" do
    it "resolves a root-only xml:lang for every descendant" do
      xml = <<~XML
        <metanorma xml:lang="fr">
          <sections><clause id="s1"><p>#{en_text}</p></clause></sections>
        </metanorma>
      XML
      res = described_class.for_node(xml_node(xml, "//p"))
      expect(res.lang).to eq("fr")
      expect(res.source).to eq("markup")
    end

    it "lets the nearest ancestor-or-self override win" do
      xml = <<~XML
        <metanorma xml:lang="en">
          <sections><clause id="s1"><p>#{en_text}</p></clause></sections>
          <annex id="A" xml:lang="fr">
            <clause id="A.1" xml:lang="de"><p>#{de_text}</p></clause>
            <p>#{fr_text}</p>
          </annex>
        </metanorma>
      XML
      expect(described_class.for_node(xml_node(xml, "//clause[@id='A.1']"))
        .lang).to eq("de")
      expect(described_class.for_node(xml_node(xml, "//annex/p"))
        .lang).to eq("fr")
      expect(described_class.for_node(xml_node(xml, "//clause[@id='s1']"))
        .lang).to eq("en")
    end

    it "reads xml:lang through the XML namespace (real standoc trees)" do
      xml = <<~XML
        <metanorma xmlns="https://www.metanorma.org/ns/standoc" xml:lang="fr">
          <sections><clause><p>#{en_text}</p></clause></sections>
        </metanorma>
      XML
      res = described_class.for_node(
        xml_node(xml, "//*[local-name()='p']")
      )
      expect(res.lang).to eq("fr")
      expect(res.source).to eq("markup")
    end

    it "skips xml:lang=\"\" and keeps walking up (§2.12)" do
      xml = <<~XML
        <metanorma xml:lang="">
          <annex xml:lang="fr"><p>#{fr_text}</p></annex>
          <sections><clause><p>#{en_text}</p></clause></sections>
        </metanorma>
      XML
      expect(described_class.for_node(xml_node(xml, "//annex/p"))
        .lang).to eq("fr")
      res = described_class.for_node(xml_node(xml, "//clause/p"))
      expect(res.lang).to eq("en")
      expect(res.source).to eq("heuristic")
    end

    it "detects a translated annex with no markup at all (the " \
       "canonical case: a French terminology annex in an EN edition)" do
      xml = <<~XML
        <metanorma>
          <sections><clause id="s1"><p>#{en_text}</p></clause></sections>
          <annex id="B"><p>#{fr_text}</p></annex>
        </metanorma>
      XML
      annex = described_class.for_node(xml_node(xml, "//annex"))
      expect(annex.lang).to eq("fr")
      expect(annex.source).to eq("heuristic")
      body = described_class.for_node(xml_node(xml, "//clause"))
      expect(body.lang).to eq("en")
      expect(body.source).to eq("heuristic")
    end

    it "uses the document default for inconclusive text" do
      xml = "<metanorma><sections><clause><p>Reserved.</p></clause>" \
            "</sections></metanorma>"
      res = described_class.for_node(xml_node(xml, "//p"), default: "en")
      expect(res.lang).to eq("en")
      expect(res.source).to eq("default")
    end

    it "ends at the explicit fallback when the corpus declares " \
       "nothing and detection fails" do
      xml = "<metanorma><sections><clause><p>Reserved.</p></clause>" \
            "</sections></metanorma>"
      res = described_class.for_node(xml_node(xml, "//p"))
      expect(res.lang).to eq(described_class::DEFAULT_LANG)
      expect(res.source).to eq("fallback")
    end
  end

  describe ".for_document" do
    it "prefers the root xml:lang" do
      root = Nokogiri::XML("<metanorma xml:lang=\"fr\">#{fr_text}</metanorma>").root
      res = described_class.for_document(root, declared: "en")
      expect(res).to eq(described_class::Resolution.new(lang: "fr",
                                                        source: "markup"))
    end

    it "takes the declared language when the root carries no xml:lang" do
      root = Nokogiri::XML("<metanorma>#{fr_text}</metanorma>").root
      res = described_class.for_document(root, declared: "en")
      expect(res.lang).to eq("en")
      expect(res.source).to eq("default")
    end

    it "detects at document level when nothing is declared" do
      root = Nokogiri::XML("<metanorma>#{fr_text}</metanorma>").root
      res = described_class.for_document(root)
      expect(res.lang).to eq("fr")
      expect(res.source).to eq("heuristic")
    end

    it "ends at the explicit fallback" do
      root = Nokogiri::XML("<metanorma><clause/></metanorma>").root
      res = described_class.for_document(root)
      expect(res.lang).to eq(described_class::DEFAULT_LANG)
      expect(res.source).to eq("fallback")
    end
  end

  describe "the repo's own corpus (spec/fixtures/standoc)" do
    # Verification against a real fixture: this semantic XML carries
    # NO xml:lang anywhere — the document language lives in
    # bibdata/language. The resolver must not invent markup.
    let(:fixture_xml) do
      File.read(File.expand_path("../../fixtures/standoc/requirements/document.xml",
                                 __dir__), encoding: "utf-8")
    end
    let(:doc) { Nokogiri::XML(fixture_xml) }

    it "resolves the document from the declared language (default)" do
      res = described_class.for_document(doc.root, declared: "en")
      expect(res.lang).to eq("en")
      expect(res.source).to eq("default")
    end

    it "detects the document language from its text when undeclared" do
      res = described_class.for_document(doc.root)
      expect(res.lang).to eq("en")
      expect(res.source).to eq("heuristic")
    end

    it "detects an English element from its own text" do
      req = doc.at_xpath("//*[local-name()='requirement']")
      res = described_class.for_node(req)
      expect(res.lang).to eq("en")
      expect(res.source).to eq("heuristic")
    end
  end
end
