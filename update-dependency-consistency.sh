#!/bin/bash

echo "Checking dependency inconsistency >>>"
#dart pub global activate borg
# source .bash_profile
borg probe > dependency_inconsistency.txt

echo "Updating all dependency to consistency >>>"
dart run ./lib/tool/update_all_dependency_consitency.dart