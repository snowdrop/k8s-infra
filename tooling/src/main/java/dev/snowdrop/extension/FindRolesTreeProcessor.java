package dev.snowdrop.extension;

import dev.snowdrop.type.Role;
import org.asciidoctor.ast.Block;
import org.asciidoctor.ast.Document;
import org.asciidoctor.ast.Section;
import org.asciidoctor.ast.StructuralNode;
import org.asciidoctor.extension.Treeprocessor;
import org.asciidoctor.jruby.ast.impl.BlockImpl;
import org.asciidoctor.jruby.ast.impl.SectionImpl;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static dev.snowdrop.Helper.roles;

public class FindRolesTreeProcessor extends Treeprocessor {

    private final static String KEYWORD_ROLE = "Command";
    private final static String KEYWORD_TYPE = "Cluster target type";
    private final static String KEYWORD_DESCRIPTION = "Description";

    @Override
    public Document process(Document document) {
        processBlock((StructuralNode) document);
        return document;
    }

    private void processBlock(StructuralNode node) {

        // Define a selector to find the sections starting with name "Command"
        Map<Object, Object> selector = new HashMap<Object, Object>();
        selector.put("context", ":section");

        // Search about the section within the document
        List<StructuralNode> findBy = node.findBy(selector);

        // Role
        Role role;
        int counter = 0;

        // Loop though the sections
        for (int i = 0; i < findBy.size(); i++) {
            final StructuralNode subNode = findBy.get(i);
            role = new Role();
            String sectionTitle = subNode.getTitle();
            List<StructuralNode> blocks = subNode.getBlocks();

            if (sectionTitle.startsWith(KEYWORD_ROLE)) {
                // If the node's title is equal to the keyword, then extract the name
                String[] roleName = subNode.getTitle().split(": ");
                // System.out.println("Name: " + roleName[1]);
                role.setName(roleName[1]);

                // Iterate through the nodes to find either the block containing the paragraph
                // where the paragraph contains the Type of the cluster
                for (int j = 0; j < blocks.size(); j++) {
                    final StructuralNode currentBlock = blocks.get(j);
                    if (currentBlock instanceof BlockImpl) {
                        // Search about the paragraph containing the "Type"
                        String content = currentBlock.getContent().toString();
                        if (content.startsWith(KEYWORD_TYPE)) {
                            String[] typeName = content.split(": ");
                            role.setType(typeName[1]);
                        }
                        continue;
                    }

                    if (currentBlock instanceof SectionImpl) {
                        Section section = (SectionImpl) currentBlock;
                        if (section.getTitle().startsWith(KEYWORD_DESCRIPTION)) {
                            role.setDescription(section.getBlocks().get(0).getContent().toString());
                            roles.put(++counter, role);
                        }
                        continue;
                    }
                }
            }
        }


        for (Integer key : roles.keySet()) {
            final Role aRole = roles.get(key);
            System.out.println("idx: " + key + ", role name: " + aRole.getName() + " type: " + aRole.getType() + " and description: " + aRole.getDescription());
        }
    }

    public Block convertToTable(Block originalBlock) {
        Map<Object, Object> options = new HashMap<Object, Object>();
        Block block = createBlock(
                (StructuralNode) originalBlock.getParent(),
                "listing",
                originalBlock.getLines(),
                originalBlock.getAttributes(),
                options);

        block.addRole("mytable");
        return block;
    }

}
