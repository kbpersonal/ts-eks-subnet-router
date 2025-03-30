OUTPUT_FILE = providers-aws.tf

generate-providers:
	@> $(OUTPUT_FILE); \
	regions=$$(grep 'regions' terraform.tfvars | sed 's/regions = \[\(.*\)\]/\1/' | tr -d '"'); \
	echo "Regions parsed: $$regions"; \
	unique_regions=$$(echo $$regions | tr ',' '\n' | sort -u | tr '\n' ' '); \
	echo "Unique regions: $$unique_regions"; \
	region_count=$$(echo $$unique_regions | tr ' ' '\n' | wc -w); \
	echo "Unique Regions count: $$region_count"; \
	for region in $$unique_regions; do \
		echo "Generating provider for region: $$region"; \
		echo "provider \"aws\" {" >> $(OUTPUT_FILE); \
		echo "  alias = \"$$region\"" >> $(OUTPUT_FILE); \
		echo "  region = \"$$region\"" >> $(OUTPUT_FILE); \
		echo "}" >> $(OUTPUT_FILE); \
	done