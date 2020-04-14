package dev.snowdrop.extension;

import dev.snowdrop.type.Role;
import org.asciidoctor.ast.*;
import org.asciidoctor.extension.Treeprocessor;
import org.asciidoctor.jruby.ast.impl.BlockImpl;
import org.asciidoctor.jruby.ast.impl.SectionImpl;
import org.asciidoctor.jruby.ast.impl.TableImpl;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static dev.snowdrop.Helper.cfg;
import static dev.snowdrop.Helper.roles;

public class CreateTableTreeProcessor extends Treeprocessor {

    private final static String KEYWORD_ROLE = cfg.getRoleKeyword();
    private final static String KEYWORD_TYPE = cfg.getClusterTypeKeyword();
    private final static String KEYWORD_DESCRIPTION = cfg.getDescriptionKeywork();
    private final static String ROLE_ATTRIBUTE_NAME = cfg.getRoleAttributeName();

    @Override
    public Document process(Document document) {

        // Populate Roles HashMap
        createRoleHashMap(document);

        // Define a selector to find the sections starting with name "Command"
        Map<Object, Object> selector = new HashMap<Object, Object>();
        selector.put("context", ":table");
        // Search about the section within the document
        List<StructuralNode> findBy = document.findBy(selector);
        System.out.println("FindBy size: " + findBy.size());

        for (int i = 0; i < findBy.size(); i++) {
            StructuralNode table = (TableImpl)findBy.get(i);
            for (Map.Entry<String, Object> entry : table.getAttributes().entrySet()) {
                String k = entry.getKey();
                if (k.contains("attributes")) {
                    String attributes = (String)entry.getValue();
                    for (String attr : attributes.split(",")) {
                        if (attr.contentEquals(ROLE_ATTRIBUTE_NAME)) {
                            table.getBlocks().add(populateTable((Table) table));
                        }
                    }
                }
            }

        }
        return document;
    }

    private void createRoleHashMap(StructuralNode node) {

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

    private Table populateTable(Table table) {
        // Create the needed columns and add them to the table
        Column roleColumn = createTableColumn(table, 0);
        Column typeColumn = createTableColumn(table, 1);
        Column descriptionColumn = createTableColumn(table, 2);

        // Define how the content will be aligned within the column
        alignColumnData(roleColumn);
        alignColumnData(typeColumn);
        alignColumnData(descriptionColumn);

        table.getColumns().add(roleColumn);
        table.getColumns().add(typeColumn);
        table.getColumns().add(descriptionColumn);

        // Create a row and the cells
        for (Integer key : roles.keySet()) {
            final Role aRole = roles.get(key);
            //System.out.println("idx: " + key + ", role name: " + aRole.getName() + " type: " + aRole.getType() + " and description: " + aRole.getDescription());
            Row row = createTableRow(table);
            Cell cell = createTableCell(roleColumn, aRole.getName());
            row.getCells().add(cell);

            cell = createTableCell(roleColumn, aRole.getType());
            row.getCells().add(cell);

            cell = createTableCell(roleColumn, aRole.getDescription());
            row.getCells().add(cell);

            // Append the row to the table
            table.getBody().add(row);
        }

        System.out.println("Table generated !");
        return table;
    }

    private void alignColumnData(Column column) {
        column.setHorizontalAlignment(Table.HorizontalAlignment.CENTER);
        column.setVerticalAlignment(Table.VerticalAlignment.BOTTOM);
    }

}
