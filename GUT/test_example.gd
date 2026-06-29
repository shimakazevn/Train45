extends GutTest

func test_example() -> void:
	const EXAMPLE_STRING := "Dialogic!"

	assert_eq(EXAMPLE_STRING.length(), 9)
	assert_string_starts_with(EXAMPLE_STRING, "Dia")
	assert_string_contains(EXAMPLE_STRING, "logic")
