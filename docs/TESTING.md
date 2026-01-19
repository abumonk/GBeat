# GBeat Automated Testing Documentation

## Overview

GBeat uses a custom lightweight test framework designed for Godot 4.x headless execution. Tests verify the functionality of all core systems including the sequencer, combat, audio, save system, abilities, boss mechanics, and visual effects.

## Running Tests

### Command Line (Headless)

```bash
godot --headless --script res://tests/test_runner.gd
```

### From Editor

1. Open `tests/test_runner.gd`
2. Run the project with this script as the main scene
3. View results in the output console

## Test Structure

### File Organization

```
tests/
├── test_runner.gd       # Main test runner
├── test_base.gd         # Base class with assertions
├── test_quant.gd        # Quant system tests
├── test_pattern.gd      # Pattern system tests
├── test_combat_types.gd # Combat type tests
├── test_movement_types.gd # Movement type tests
├── test_save_types.gd   # Save system tests
├── test_ability_types.gd # Ability system tests
├── test_boss_types.gd   # Boss system tests
├── test_audio_types.gd  # Audio system tests
├── test_vfx_types.gd    # VFX system tests
└── test_beat_detector.gd # Beat detection tests
```

### Naming Conventions

- Test files must start with `test_` prefix
- Test methods must start with `test_` prefix
- Test files must be in the `tests/` directory

## Writing Tests

### Basic Test Structure

```gdscript
extends TestBase

func test_example() -> bool:
    var result := some_function()

    if not assert_equal(result, expected_value):
        return false

    return true
```

### Available Assertions

| Method | Description |
|--------|-------------|
| `assert_true(condition, message)` | Assert condition is true |
| `assert_false(condition, message)` | Assert condition is false |
| `assert_equal(actual, expected, message)` | Assert values are equal |
| `assert_not_equal(actual, not_expected, message)` | Assert values are not equal |
| `assert_null(value, message)` | Assert value is null |
| `assert_not_null(value, message)` | Assert value is not null |
| `assert_greater(actual, expected, message)` | Assert actual > expected |
| `assert_less(actual, expected, message)` | Assert actual < expected |
| `assert_in_range(value, min, max, message)` | Assert value in range |
| `assert_approximately(actual, expected, epsilon, message)` | Assert float equality |
| `assert_array_contains(array, element, message)` | Assert array contains element |
| `assert_array_size(array, size, message)` | Assert array has size |
| `assert_string_contains(string, substring, message)` | Assert string contains substring |
| `fail(message)` | Explicitly fail test |

### Setup and Teardown

```gdscript
extends TestBase

func _setup() -> void:
    # Called before each test method
    pass

func _teardown() -> void:
    # Called after each test method
    pass

func _cleanup() -> void:
    # Called after all tests in class complete
    pass
```

## Test Coverage

### Core Systems

| System | Test File | Coverage |
|--------|-----------|----------|
| Quant | `test_quant.gd` | Creation, types, ranges |
| Pattern | `test_pattern.gd` | BPM calculations, quant queries, JSON serialization |
| Combat | `test_combat_types.gd` | Action types, timing ratings, multipliers, hit results |
| Movement | `test_movement_types.gd` | State creation, input handling |
| Save | `test_save_types.gd` | Serialization, deserialization, all data types |
| Abilities | `test_ability_types.gd` | Categories, effects, states |
| Boss | `test_boss_types.gd` | States, phases, damage, stagger |
| Audio | `test_audio_types.gd` | Layers, SFX, crossfade types |
| VFX | `test_vfx_types.gd` | Pulse modes, color palettes |
| Beat Detection | `test_beat_detector.gd` | Energy calculation, BPM detection |

### Test Categories

1. **Unit Tests**: Test individual classes and methods
2. **Data Tests**: Test serialization/deserialization
3. **Math Tests**: Test calculations (BPM, damage, multipliers)
4. **State Tests**: Test state machines and transitions

## Best Practices

### Do

- Write focused tests that test one thing
- Use descriptive test method names
- Include meaningful assertion messages
- Test edge cases (empty arrays, zero values, etc.)
- Keep tests independent of each other

### Don't

- Don't rely on test execution order
- Don't access external resources (files, network)
- Don't create nodes that require scene tree (use RefCounted)
- Don't make tests depend on other tests

## Continuous Integration

Tests can be run in CI pipelines:

```yaml
test:
  script:
    - godot --headless --script res://tests/test_runner.gd
  allow_failure: false
```

Exit code is the number of failed tests (0 = success).

## Adding New Tests

1. Create new file `tests/test_<feature>.gd`
2. Extend `TestBase`
3. Add methods starting with `test_`
4. Return `true` for pass, `false` for fail
5. Use assertions for validation

Example:

```gdscript
## Test cases for new feature
extends TestBase

func test_new_feature_basic() -> bool:
    var instance := NewFeature.new()

    if not assert_not_null(instance):
        return false
    if not assert_equal(instance.default_value, 0):
        return false

    return true

func test_new_feature_calculation() -> bool:
    var result := NewFeature.calculate(10, 20)

    if not assert_equal(result, 30):
        return false

    return true
```

## Troubleshooting

### Common Issues

**"Failed to open tests directory"**
- Ensure `tests/` directory exists at project root

**Test not discovered**
- Verify file starts with `test_`
- Verify file ends with `.gd`
- Check file is in `tests/` directory

**Assertion fails silently**
- Always return `false` after failed assertion
- Chain assertions with `if not assert_...:`

**Node-related errors**
- Use `RefCounted` base class instead of `Node`
- Avoid scene tree dependencies in unit tests
