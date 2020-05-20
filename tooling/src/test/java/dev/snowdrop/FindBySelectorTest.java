package dev.snowdrop;

import org.asciidoctor.Asciidoctor;
import org.asciidoctor.ast.Document;
import org.asciidoctor.ast.StructuralNode;
import org.junit.Before;
import org.junit.Test;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.hamcrest.Matchers.greaterThan;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.collection.IsCollectionWithSize.hasSize;
import static org.junit.Assert.assertThat;

public class FindBySelectorTest {

    private Asciidoctor asciidoctor;

    @Before
    public void before() {
        asciidoctor = Asciidoctor.Factory.create();
    }

    @Test
    public void findByImages() {

        String DOCUMENT = "= Document Title\n" +
                "\n" +
                "preamble\n" +
                "\n" +
                "== Section A\n" +
                "\n" +
                "paragraph\n" +
                "\n" +
                "--\n" +
                "Exhibit A::\n" +
                "+\n" +
                "[#tiger.animal]\n" +
                "image::tiger.png[Tiger]\n" +
                "--\n" +
                "\n" +
                "image::cat.png[Cat]\n" +
                "\n" +
                "== Section B\n" +
                "\n" +
                "paragraph";

        Document document = asciidoctor.load(DOCUMENT, new HashMap<String, Object>());

        Map<Object, Object> selector = new HashMap<Object, Object>();
        selector.put("context", ":image");
        List<StructuralNode> findBy = document.findBy(selector);

        System.out.println("Content : " + document.getContent());

        assertThat(findBy, hasSize(2));
        assertThat((String) findBy.get(0).getAttributes().get("target"), is("tiger.png"));
        assertThat(findBy.get(0).getLevel(), greaterThan(0));

        assertThat((String) findBy.get(1).getAttributes().get("target"), is("cat.png"));
    }
}
