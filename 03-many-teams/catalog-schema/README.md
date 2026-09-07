# catalog-schema

The published product contract. Every field the storefront may show is declared
here once, in `catalog.json`, and nothing else in the organisation is allowed to
invent one.

It is a JSON file rather than a service on purpose: a contract that needs a
process running to be read is a contract nobody reads.
