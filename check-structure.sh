#!/bin/bash

echo "=== Checking Terraform Structure ==="

echo -e "\n1. Root level files:"
ls -la *.tf

echo -e "\n2. Networking module files:"
ls -la modules/networking/

echo -e "\n3. OKE module files:"
ls -la modules/oke/

echo -e "\n4. Searching for route table resources:"
grep -n "oci_core_route_table" modules/networking/*.tf || echo "Not found in networking module"

echo -e "\n5. Searching for subnet resources:"
grep -n "oci_core_subnet" modules/networking/*.tf || echo "Not found in networking module"

echo -e "\n6. Searching for internet gateway:"
grep -n "oci_core_internet_gateway" modules/networking/*.tf || echo "Not found"

echo -e "\n7. Content of newmain.tf (first 50 lines):"
head -50 modules/networking/newmain.tf 2>/dev/null || echo "newmain.tf not found"

