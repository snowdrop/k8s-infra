package dev.snowdrop;

import dev.snowdrop.extension.CreateTableTreeProcessor;
import org.asciidoctor.Asciidoctor;
import org.asciidoctor.OptionsBuilder;
import org.asciidoctor.SafeMode;

import java.io.File;

public class AsciidoctorGenerator {

    public static void main(String[] args) {
        String adocFile = args[0];
        try (Asciidoctor asciidoctor = Asciidoctor.Factory.create()) {

            // Include the Table extension
            asciidoctor.javaExtensionRegistry()
                    .treeprocessor(CreateTableTreeProcessor.class);

            // Generate HTML
            asciidoctor.convertFile(
                    new File(adocFile),
                    OptionsBuilder.options()
                            .toFile(true)
                            .safe(SafeMode.UNSAFE));

            // Generate PDF
            /*
            asciidoctor.convertFile(
            new File(adocFile),
            OptionsBuilder.options()
                    .backend("pdf")
                    .toFile(true)
                    .safe(SafeMode.UNSAFE));
            */
        }
    }
}
