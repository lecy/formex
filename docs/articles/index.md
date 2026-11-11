# Articles

### Package overview

Start here. Three short tours of what the package does: how it guesses a
column’s type, the shared ontology those types live in, and how it
cleans and standardizes values.

- [Guess Data
  Type](https://lecy.github.io/formex/articles/overview-guess-data-type.md):
- [The
  Ontology](https://lecy.github.io/formex/articles/overview-ontology.md):
- [Formatting
  Syntax](https://lecy.github.io/formex/articles/overview-formatting-syntax.md):

### Data Types

What kinds of column research data contains, and the ontology that maps
them.

- [The Data-Type
  Ontology](https://lecy.github.io/formex/articles/data-type-ontology.md):
- [The Type
  Atlas](https://lecy.github.io/formex/articles/formex-type-atlas.md):

### Data Type Detection

The architecture that routes a column to its type: detectors, the
learned router, and the feature profile it reads.

- [Guessing a Column's
  Type](https://lecy.github.io/formex/articles/guess-data-type.md):
- [Feature Engineering for Type
  Guessing](https://lecy.github.io/formex/articles/feature-engineering.md):

### Detector Types

How each kind of detector recognizes a format — masks, lexicons, shapes
— and how building each one differs.

- [How Detectors Recognize a
  Type](https://lecy.github.io/formex/articles/detector-kinds.md):
- [Data-Type Detector
  Guide](https://lecy.github.io/formex/articles/data-type-detectors.md):

### Testing Libraries

The example corpora, the stress-test grid, and building a feature
dataset to train and evaluate column-type classifiers.

- [The Testing
  Libraries](https://lecy.github.io/formex/articles/testing-libraries.md):
- [Benchmarking and the Stress-Test Design
  Grid](https://lecy.github.io/formex/articles/benchmarking.md):
- [Building a Feature Dataset for
  Classification](https://lecy.github.io/formex/articles/feature-dataset.md):
- [Classifying Columns with a Decision
  Tree](https://lecy.github.io/formex/articles/classifier-decision-tree.md):

### Extending the Library

Growing the package: the AutoType negative-generation framework for
refining masks, a synthetic-data strategy via the temporal case, and the
end-to-end steps to add a detector.

- [The AutoType
  Framework](https://lecy.github.io/formex/articles/autotype-framework.md):
- [Synthetic Data: the Temporal
  Case](https://lecy.github.io/formex/articles/synthetic-data-temporal.md):
- [Adding a
  Detector](https://lecy.github.io/formex/articles/adding-a-detector.md):

### Formex Syntax

The recipe language that governs how a raw value is read, cleaned, and
rewritten to a stable, analysis-ready form.

- [Formex: the format-expression
  syntax](https://lecy.github.io/formex/articles/formex.md):
