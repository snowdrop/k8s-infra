package dev.snowdrop;


import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.util.Arrays;
import java.util.List;

import org.asciidoctor.Asciidoctor;
import org.asciidoctor.Attributes;
import org.asciidoctor.AttributesBuilder;
import org.asciidoctor.OptionsBuilder;
import org.asciidoctor.Placement;
import org.asciidoctor.SafeMode;
import org.yaml.snakeyaml.Yaml;
import org.yaml.snakeyaml.constructor.Constructor;

import dev.snowdrop.type.Config;

public class AsciidoctorGenerator {

    public static void main(String[] args) {
        System.out.println(Arrays.toString(args));
        // Parse the yaml config
        Yaml yaml = new Yaml(new Constructor(Config.class));
        Asciidoctor asciidoctor = Asciidoctor.Factory.create();
        try {
            Config cfg = yaml.load(new FileReader(args[0]));
            String adocFiles = cfg.getDestinationFile();
            File fileAdoc = new File(cfg.getAsciidoctorFile());
            Attributes attributes = AttributesBuilder.attributes().backend("html5").icons("font")
                    .tableOfContents(Placement.LEFT).tableOfContents(true).get();
            asciidoctor.convertFile(fileAdoc, OptionsBuilder.options().attributes(attributes).backend("html5")
                    .toFile(new File(cfg.getDestinationFile())).safe(SafeMode.UNSAFE));
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        }
    }
}
