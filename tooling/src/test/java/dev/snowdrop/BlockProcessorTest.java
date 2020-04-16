package dev.snowdrop;

import org.asciidoctor.Asciidoctor;
import org.asciidoctor.ast.Document;
import org.asciidoctor.ast.StructuralNode;
import org.asciidoctor.extension.BlockProcessor;
import org.asciidoctor.extension.Name;
import org.asciidoctor.extension.Reader;
import org.jsoup.Jsoup;
import org.junit.Before;
import org.junit.Test;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static java.util.stream.Collectors.joining;
import static java.util.stream.Collectors.toList;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;

public class BlockProcessorTest {

    private Asciidoctor asciidoctor;

    @Before
    public void before() {
        asciidoctor = Asciidoctor.Factory.create();
    }

    @Test
    public void convertBlockToUppercase() {
        String s = "= Test\n" +
                "\n" +
                "== A section\n" +
                "\n" +
                "[test]\n" +
                "Hello World\n";

        asciidoctor.javaExtensionRegistry().block(BlockCreator.class);
        Document document = asciidoctor.load(s, new HashMap<String, Object>());
        assertNotNull(document.getBlocks());

        String result = (String) document.getContent();
        System.out.println("Content : " + result);
        assertEquals("H e l l o W o r l d", Jsoup.parse(result).select("div.paragraph > p").first().text());
    }

    @Name("test")
    public static class BlockCreator extends BlockProcessor {
        @Override
        public Object process(StructuralNode parent, Reader reader, Map<String, Object> attributes) {
            List<String> s = reader.readLines().stream()
                    .map(line ->
                            line.chars()
                                    .mapToObj(c -> Character.toString((char) c))
                                    .collect(joining(" ")))
                    .collect(toList());
            return createBlock(parent, "paragraph", s);
        }
    }
}
