## data-raw/datatypes/person.R
## Positive examples for the PERSON-NAME family. Drawn from the internal SSA
## given-name and Census surname gazetteers (R/dt-name-data.R) so every example
## is a covered name. full_name mixes given-name-led "First Last" and
## "Last, First" shapes, including a middle initial.

first_name <- c(
  "James", "Mary", "Robert", "Patricia", "Michael", "Jennifer", "William",
  "Elizabeth", "David", "Olivia", "Noah", "Emma", "Liam", "Sophia", "Grace"
)

last_name <- c(
  "Smith", "Johnson", "Williams", "Brown", "Garcia", "Martinez", "Nguyen",
  "Patel", "Kim", "Rodriguez", "Lee", "Chen", "Hernandez", "Wong", "Singh"
)

full_name <- c(
  "John Smith", "Mary Johnson", "Robert Brown", "James Williams",
  "Patricia Garcia", "Michael Davis", "Mary J. Cooper", "David A. Wilson",
  "Smith, John", "Garcia, Maria", "Johnson, Robert", "Nguyen, Anna"
)
