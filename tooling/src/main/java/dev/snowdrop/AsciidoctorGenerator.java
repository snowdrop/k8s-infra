package dev.snowdrop;

import dev.snowdrop.extension.CreateTableTreeProcessor;
import dev.snowdrop.type.Config;
import org.asciidoctor.Asciidoctor;
import org.asciidoctor.OptionsBuilder;
import org.asciidoctor.SafeMode;
import org.yaml.snakeyaml.Yaml;
import org.yaml.snakeyaml.constructor.Constructor;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;

import static dev.snowdrop.Helper.cfg;

public class AsciidoctorGenerator {

    public static void main(String[] args) {

        // Parse the yaml config
        Yaml yaml = new Yaml(new Constructor(Config.class));
        try {
            cfg = yaml.load(new FileReader(args[0]));

            String adocFile = cfg.getAsciidoctorFile();
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
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        }
    }
}
