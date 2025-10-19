# ============================================
# NETWORKING MODULE DATA SOURCES - REFACTORED
# ============================================

data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}