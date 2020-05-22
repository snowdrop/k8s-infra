Issues to fix
====

Shellcheck[1] still report a couple of issues:

$ shellcheck generate-ansible-roles-doc.sh

In generate-ansible-roles-doc.sh line 7:
for FILE in $(find ${path} -name '**.adoc')
            ^-----------------------------^ SC2044: For loops over find output are fragile. Use find -exec or a while read loop.


In generate-ansible-roles-doc.sh line 9:
  paths+="include::../$FILE[]\n\n"
                      ^-- SC1087: Use braces when expanding arrays, e.g. ${array[idx]} (or ${var}[.. to quiet).

For more information:
  https://www.shellcheck.net/wiki/SC1087 -- Use braces when expanding arrays,...
  https://www.shellcheck.net/wiki/SC2044 -- For loops over find output are fr...

