package dev.snowdrop;

import org.asciidoctor.Asciidoctor;
import org.asciidoctor.ast.Block;
import org.asciidoctor.ast.Document;
import org.asciidoctor.ast.StructuralNode;
import org.asciidoctor.extension.BlockMacroProcessor;
import org.hamcrest.CoreMatchers;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Element;
import org.junit.Before;
import org.junit.Test;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import static org.junit.Assert.assertThat;

public class BlockMacroProcessorTest {

    private Asciidoctor asciidoctor;

    @Before
    public void before() {
        asciidoctor = Asciidoctor.Factory.create();
    }

    @Test
    public void convertBlockMacroToUppercase() {
        String s = "= Test\n" +
                "\n" +
                "== A section\n" +
                "\n" +
                "test::Hello World[]\n" +
                ".\n";

        asciidoctor.javaExtensionRegistry().blockMacro("test",TableMacro.class);
        Document doc = asciidoctor.load(s, new HashMap<String, Object>());
        org.jsoup.nodes.Document content = Jsoup.parse(doc.getContent().toString(), "UTF-8");
        System.out.println(content);

        Element contentElement = content.getElementsByAttributeValue("class", "content").first();
        assertThat(contentElement.text(), CoreMatchers.is("Hello World"));
    }

    public static class TableMacro extends BlockMacroProcessor {
        public TableMacro(String macroName) {
            super(macroName);
        }
        public TableMacro(String macroName, Map<String, Object> config) {
            super(macroName, config);
        }

        @Override
        public Block process(StructuralNode parent, String target, Map<String, Object> attributes) {
            String content = "<div class=\"content\">\n" +
                    "<h4>" + target + "</h4>\n" +
                    "</div>";
            return createBlock(parent, "pass", Arrays.asList(content), attributes);
        }
    }
}
