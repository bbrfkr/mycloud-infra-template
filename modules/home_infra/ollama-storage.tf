resource "openstack_objectstorage_container_v1" "ollama_storage_container" {
  region = "RegionOne"
  name   = "${var.environment_name}-ollama-storage"
}
