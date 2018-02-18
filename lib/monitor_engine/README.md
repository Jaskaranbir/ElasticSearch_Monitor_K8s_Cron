# JSON Template-Based Comparison

This "module" (call it gem/module/whatever suits your programmer-soul). The base idea is to compare two JSON objects without conditional statements.

One additional advantage is that you no longer need to check for *existence* of parent key for checking/verifying the value of child key.

---

**Index:**

- [How does it work][1]
- [Why][2]
- [Current Limitations / TODOs][3]
- **[How to use][4]**
  - [The error object][5]
  - [Change how the error output is dealt with][6]
  - [How is the final error-output object formed][7]
  - [Basic Example][8]
  - [Providing multiple possible values][9]
  - [Wildcards][10]
    - [Array Wildcards][11]
      - [`___AND`][11]
      - [`___OR`][12]
      - [`___ARRAY_INDEX`][13]
      - [Math-Operations Wildcards][14]
        - [`___BT`][15]
        - [`___EQ`][16]
        - [`___GT`][17]
        - [`___LT`][18]
    - [Hash Wildcards][19]
        - [`___*`][20]
        - [`___OPTIONAL`][21]
- [How to Contribute][22]
- [License][23]

---

## How does it work

You provide the ***`rules`*** and the ***`scan-data`***. The scan-data is validated based on provided rules. Any keys/values found not in accordance with the rules are reported.

By default, it just prints the errored keys/values while specifying what sort of error occurred (check [alert_helper][24] for error types and how error-logs are `transported`).

Nothing will be printed if there were no errors found and all rules succeeded.

---

## Why

* Couldn't find something similar "on the internet" (at time of this write-up).
* Because I wanted to.

**Why use this?**

Here's a sample JSON data:

    {
      "a": 4,
      "b": {
        "c": {
          "d": [
            1,
            2,
            3
          ]
        }
      },
      "e": 8,
      "f": 'green'
    }

Now, imagine doing this:

    if (data[a] && data[a] > 4)
      # --
    end

    if (data[b] && data[b][c] && data[b][c][d] && data[b][c][d].include?(2))
      # --
    end

    # Or doing this:

    if (data[b] && data[b][c] && data[b][c][d])
      data[b][c][d].each do | e |
        if (e > 4)
          # --
        end
      end
    end

    if (data[f] && data[f] == 'green' || data[f] == 'yellow')
      # --
    end

...versus doing this:

    {
      a: [:'___GT', 4],
      b: {
        c: {
          d: [
            {
              '___AND': 2
            },
            [
              '___GT': 4
            ]
          ]
        }
      },

      f: ['green', 'yellow']
    }

Which one's easier to read, understand, and deal with? I leave the answer to you...

***But, what about performance,*** you ask?

Performance depends on rules you provide. In other words, it won't be drastically different compared to if you would manually use `if-else` statements. The code works by simply scanning (or more specifically, recursively iterating) the rules. Yes, this will have slightly higher performance impact. But is that really a concern, when the computers these days are so fast, and easy to scale? Is the loss of developer productivity worth it? Again, I leave the answer to you...

---

## Current Limitations / TODOs

*(Discovered so far).*

* Can't create a rule such as `Any value of datatype x`.
* Can't specify the number of elements in array, or number of keys in Hash

---

## How to use

* Call the [`monitor`][25] method of [`MonitorEngine`][26] class. This method takes 2 parameters.

  * `scan_data`: The data which has to be scanned for errors (values that don't match provided rules).

  * `rules`: The rules using which data has to be compared. Any data not matching these rules will count as errors.

As explained above, the usage consists of `rules` (what values should JSON data contain) and `scan-data` (JSON data to scan and match with `rules`).

* **Check below for [Usage Examples][8]**

**Rules are to be written as Ruby Symbolic-Hash (Hash with symbols as keys, instead of strings).**

### The error object

If some rule doesn't match for some reason, an error object is printed to stdout. This error object/*Hash* hash two fields:

* **error_obj**: The actual error-object containing errors occured and actual values. This object contains JSON structure that corresponds to the original `scan-data`'s structure.

* **error_paths**: Since `error_obj` is a JSON structure, getting all errorss would require a recursive iteration of error-object. Hence this object exists to save recursion (means you *don't* have to use recursion to navigate error object). This object is simply an array that contains strings corresponding to JSON path where the error occurred. These string(s) can be parsed to get exact error path in Hash, hence eliminating the need to use recursion.

* **Every error-indentifier-property starts with 6 underscores (`______`)**.

* **If error occurs at ROOT level of JSON, the error-path is represented by `___root`.**

*(Check below for examples).*

#### Handling error messages

The *transport* method for error messages is defined in [lib/monitor_engine/alert][27]. Currently, it just prints to stdout.

---

### Change how the error output is dealt with

...or where is error output displayed?

Simply edit the [`transport`][27] method of [lib/alert.rb][28]. This method provides two arguments:

* **error_obj**: The object containing all errors. The structure of this object matches the JSON data being scanned with rules.

* **error_paths**: Array containing key-locations in `error_obj` where the errors occured. (Also see **[above][5]**).

Just add your logic to however you would like the data to be handled here.

---

### How is the final error-output object formed

The final error object has JSON structure similar to `scan-data` provided. The **[lib/alert_helper][24]** is responsible for forming this object.

The object is formed using the idea of ***states***. A *state* can be any particular level (in terms of nesting) in JSON object. An error information is also a state, as whenever an error-data is added to result-object, a new state is added.

The states are added and `reverted` mainly using keys (keys, as in Hash). Reverting a state refers to going back to previous state.

States are basically different levels in nesting of same object (as mentioned above). The final ouput is simply using the very first state, or the top-level (or root-level) nesting state of error-object to disaply all data.

---

#### Note: All outputs in examples are formatted for readability purposes. The actual output is *NOT* formatted.

* ### Basic Example

#### Example 1

-> Sample scan-data:

    {
      "name": "minion",
      "age": 5
    }

-> Sample rule (remember, `rule` should be a symbol-based Ruby Hash):

    {
      name: 'minion',
      age: 10
    }

Will result in output:

    {
      "error_obj": {
        "age": {
          "______expected":10,
          "______got":5
        }
      },
      "error_path": ["age"]
    }

#### Example 2

-> Sample scan-data:

    {
      "category": "dogs",
      "count": {
        "water": 15,
        "fire": 6
      }
    }

-> Sample rule:

    {
      category: 'pokeman',
      count: {
        electric: 20,
        fire: 10
      }
    }

Will result in output:

    {"error_obj":{"category":{"______expected":"pokeman","______got":"dogs"},"count":{"electric":{"______key_not_found":"electric","______at_location":"___root.count"},"fire":{"______expected":10,"______got":6}}},"error_paths":["category","count.electric","count.fire"]}

Here's formatted version of output (its **not** formatted automatically by the module).

    {
      "error_obj": {
        "category": {
          "______expected": "pokeman",
          "______got": "dogs"
        },
        "count": {
          "electric": {
            "______key_not_found": "electric",
            "______at_location": "___root.count"
          },
          "fire": {
            "______expected": 10,
            "______got": 6
          }
        }
      }

      "error_paths": [
        "category",
        "count.electric",
        "count.fire"
      ]
    }

* ### Providing multiple possible values

**-> Provide multiple possible values. If one of the values match, the rule is counted as success.**

Just specify the values in an array. One of the values must match. Examples Provided for simple data-types, but complex and nested objects work just as fine.

-> Sample scan-data:

    {
      "a": 4,
      "b": "SomeText"
    }

-> Sample rules:

    {
      a: [1, 3, 4, 2, 5],
      b: ['val1', 'val2', 'val3']
    }

-> Output:

    {
      "error_obj": {
        "b": {
          "______no_match_found_from_values": ["val1", "val2", "val3"],
          "______expected_value": "SomeText"
        }
      },
      "error_path": ["b"]
    }

* ### Wildcards

To make the tool more convenient and efficient to use, there are also some wildcards implemented. **Every wildcard starts with 3 underscores (`___`)**.

### Array Wildcards

* ### `___AND`

**-> All specified values *must* be present in an array**

This checks for presence of values in array. It means that all the specified values should be contained in an array or it counts towards failed rule.

-> Sample scan-data:

    {
      "category": "dogs",
      "count": {
        "water": 15,
        "fire": 6
      },
      "names": [
        "Charlie",
        "Buddy",
        "Max",
        "Archie"
      ]
    }

-> Sample rules:

    {
      category: 'dogs',
      count: {
        water: 15,
        fire: 6
      },
      names: [
        {
          '___AND': [
            'Tom',
            'Charlie',
            'Berry',
            'Shadow',
            'Max'
          ]
        }
      }
    }

-> Output:

    {
      "error_obj": {
        "names": {
          "______array_elements_not_found": ["Tom", "Berry", "shadow"],
          "______got_array": ["Charlie", "Buddy", "Max", "Archie"]
        }
      },
      "error_paths":["names"]
    }

* ### `___OR`

**-> At least one of the specified values *must* be present in an array**

This checks for presence of values in array. It means that one of the specified values should be contained in an array or it counts towards failed rule.

-> Sample scan-data:

    {
      "category": "dogs",
      "count": {
        "water": 15,
        "fire": 6
      },
      "names": [
        "Charlie",
        "Buddy",
        "Max",
        "Archie"
      ]
    }

-> Sample rules:

    {
      category: 'dogs',
      count: {
        water: 15,
        fire: 6
      },
      names: [
        {
         '___OR': [
            'Tom',
            'Shadow'
          ]
        }
      ]
    }

-> Output:

    {
      "error_obj": {
        "names": {
          "______expected_atleast_one_value_from": ["Tom", "shadow"],
          "______got_array": ["Charlie", "Buddy", "Max", "Archie"]
        }
      },
      "error_paths":["names"]
    }

*  **You can also use both `___AND` and `___OR` at the same time.**

For example, consider these rules:

    {
      category: 'dogs',
      count: {
        water: 15,
        fire: 6
      },
      names: [
        {
          '___OR': [
            'Tom',
            'Shadow'
          ].
          '___AND': [
            'Jerry',
            'Max',
            'Buddy'
          ]
        }
      ]
    }

These rules imply that **any value out of *Tom, Shadow*, but all values from *Jerry, Max, Buddy*** should be present for rules to count as success.

* If same rule is specified under both `___OR` and `___AND`, precedence goes to `___AND`.

### -> The default operation is `AND`. Example:

-> Sample scan-data:

    [
      1,
      2,
      3,
      4,
      5
    ]

-> Sample rule:

    [
      1,
      2,
      10
    ]

The above implies that all elements from **1, 2, 10** must be present in array.

-> Output:

    {
      "error_obj": {
        "______array_elements_not_found": [10],
        "______got_array": [1,2,3,4,5]
      },
      "error_paths": ["___root"]
    }

* ### `___ARRAY_INDEX`

**-> A given value must be present at the specified index in Array**

**-> Indices are 0 based, both in scan-data and rules.**

* **The rule must be specified inside an array, otherwise data mismatch error will be thrown.**

For example, this rule is valid:

    {
      x: [
        {
          '___ARRAY_INDEX': 1,
          '___VALUE': 3
        }
      ]
    }

But this rule isn't:

    {
      x: {
        '___ARRAY_INDEX': 1,
        '___VALUE': 3
      }
    }

* #### Example 1

-> Sample scan-data:

    [
      1,
      2,
      3,
      4,
      5
    ]

-> Sample rules:

    [
      {
        '___ARRAY_INDEX': 1,
        '___VALUE': 3
      },
      {
        '___ARRAY_INDEX': 2,
        '___VALUE': 3
      },
      {
        '___ARRAY_INDEX': 4,
        '___VALUE': 10
      }
    ]

-> Output:

    {
      "error_obj": [
        {
          "______expected": 3,
          "______got": 2,
          "______at_index": 1
        },
        {
          "______expected": 10,
          "______got": 5,
          "______at_index": 4
        }
      ],
      "error_paths": [
        "___root"
      ]
    }

* #### Example 2

-> Sample scan-data:

    {
      "test": {
        "t": {
          "y": {
            "testValues": [1, 2, 3, 4, 5, 6]
          }
        },
        "x": [1, 4, 6, 7]
      }
    }'

-> Sample rules:

    {
      test: {
        t: {
          y: {
            testValues: [
              {
                '___ARRAY_INDEX': 1,
                '___VALUE': 2
              },
              {
                '___ARRAY_INDEX': 3,
                '___VALUE': 10
              },
              {
                '___ARRAY_INDEX': 2,
                '___VALUE': 5
              },
              {
                '___ARRAY_INDEX': 1,
                '___VALUE': 15
              }
            ]
          }
        },
        x: [
          {
          '___ARRAY_INDEX': 1,
          '___VALUE': 15
          }
        ]
      }
    }

-> Output:

    {
      "error_obj": {
        "test": {
          "t": {
            "y": {
              "testValues": [
                {
                  "______expected": 10,
                  "______got": 4,
                  "______at_index": 3
                },
                {
                  "______expected": 5,
                  "______got": 3,
                  "______at_index": 2
                },
                {
                  "______expected": 15,
                  "______got": 2,
                  "______at_index": 1
                }
              ]
            }
          },
          "x": [
            {
              "______expected": 15,
              "______got": 4,
              "______at_index": 1
            }
          ]
        }
      },
      "error_paths": [
        "test.t.y.testValues",
        "test.x"
      ]
    }

* ### Math-Operations Wildcards

* These operations allow you to specify rules such as *if the value should be greater than, less than, equals, or between two numbers*.

* You specify an array, containing first element as operation to be performed, and consecutive elements as the numbers on which operation is to be performed.

* **The default operation is *Equals* (`___EQ`).** For example, below rule means that the value of `x` must be *equal* to 5:

Sample rule:

    {
      x: 5
    }

* ### `___BT`

**-> The value should be between two numbers specified (*exclusively*).**

**-> Syntax: [Array]**

* First Element: *Operation Type* (`___BT`)
* Second Element: *Lower Number* (exclusive)
* Third Element: *Upper Number* (exclusive)

**Usage**:

#### Example 1:

-> Sample scan-data:

    [
      1,
      2,
      3,
      4,
      5
    ]

-> Sample rules:

    [
      {
        '___ARRAY_INDEX': 1,
        '___VALUE': [:'___GT', 30]
      },
      {
        '___ARRAY_INDEX': 2,
        '___VALUE': 3
      },
      {
        '___ARRAY_INDEX': 4,
        '___VALUE': 10
      }
    ]

-> Output:

    {
      "error_obj": [
        {
          "______math_operation_failure": ["___GT", 30],
          "______got_value": 2,
          "______at_index": 1
        },
        {
          "______expected": 10,
          "______got": 5,
          "______at_index": 4
        }
      ],
      "error_paths": ["___root"]
    }

#### Example 2:

-> Sample scan-data:

    {
      "test": {
        "t": {
          "y": 23
        },
        "x": 10,
        "z": 80,
        "a": {
          "b": 5
        }
      }
    }

-> Sample rules:

    {
      test: {
        t: {
          y: [:'___BT', 20, 25]
        },
        x: [:'___BT', 9, 11],
        z: [:'___BT', 29, 31],
        a: {
          b: [:'___BT', 2, 4]
        }
      }
    }

-> Output:

    {
      "error_obj": {
        "z": {
          "______math_operation_failure": ["___BT", 29, 31],
          "______got_value":80
        },
        "a": {
          "b": {
            "______math_operation_failure":["___BT", 2, 4],
            "______got_value":5
          }
        }
      },
      "error_paths": ["z", "a.b"]
    }

* ### `___EQ`

**-> The value should be equal to the number specified.**

**-> Syntax: [Array]**

* First Element: *Operation Type* (`___EQ`)
* Second Element: *Value*

#### Example:

-> Sample scan-data:

    {
      "x": 5
    }

-> Sample rule:

    {
      x: [:'___EQ', 4]
    }

-> Output:

    {
      "error_obj": {
        "x": {
          "______math_operation_failure": ["___EQ", 4],
          "______got_value":5
        }
      },
      "error_paths":["x"]
    }

* ### `___GT`

**-> The value should be greater than the number specified.**

**-> Syntax: [Array]**

* First Element: *Operation Type* (`___GT`)
* Second Element: *Value*

#### Example:

-> Sample scan-data:

    {
      "x": 5
    }

-> Sample rule:

    {
      x: [:'___GT', 6]
    }

-> Output:

    {
      "error_obj": {
        "x": {
          "______math_operation_failure": ["___GT", 6],
          "______got_value":5
        }
      },
      "error_paths":["x"]
    }

* ### `___LT`

**-> The value should be less than the number specified.**

**-> Syntax: [Array]**

* First Element: *Operation Type* (`___LT`)
* Second Element: *Value*

#### Example:

-> Sample scan-data:

    {
      "x": 5
    }

-> Sample rule:

    {
      x: [:'___LT', 5]
    }

-> Output:

    {
      "error_obj": {
        "x": {
          "______math_operation_failure": ["___LT", 5],
          "______got_value":5
        }
      },
      "error_paths":["x"]
    }

### Hash Wildcards

* ### `___*`

**-> This implies that the given rule should be applied to every key *within the same level* in JSON object.**

#### Example:

-> Sample scan-data:

    {
      "a": {
        "x1": 1,
        "x2": 3,
        "x3": "exampleText"
      },
      "b": {
        "y": "q",
        "z": 2
      }
    }

-> Sample rules:

    {
      a: {
        '___*': 1
      },
      b: {
        '___*': 'q'
      }
    }

-> Output:

    {
      "error_obj": {
        "a": {
          "x2": {
            "______expected": 1,
            "______got": 3
          },
          "x3": {
            "______expected": 1,
            "______got": "exampleText"
          }
        },
        "b": {
          "z": {
            "______expected": "q",
            "______got": 2
          }
        }
      },
      "error_paths": ["a.x2", "a.x3", "b.z"]
    }

* ### `___OPTIONAL`

**-> This implies that *if* the provided key is present, then it should have the provided value.** In simpler words, if some key is present, it should have the specified value. Otherwise it won't log errors regarding missing key.

#### Example:

-> Sample scan-data:

    {
      "a": 4,
      "c": 3
    }

-> Sample rules:

    {
      '___OPTIONAL': {
        a: 5,
        b: 4,
        c: 3
      }
    }

-> Output:

    {
      "error_obj": {
        "a": {
          "______expected": 5,
          "______got": 4
        }
      },
      "error_paths": ["a"]
    }

---

## How to Contribute

* Reporting bugs (provide *scan-data*, *rules* associated when you report).
* See the [**Limitations/TODO**][3] list above.
* Suggestions.

---

## License

None, really. Just use it however you like, but remember to give credits where required.


  [1]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#how-does-it-work
  [2]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#why
  [3]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#current-limitations--todos
  [4]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#how-to-use
  [5]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#the-error-object
  [6]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#change-how-the-error-output-is-dealt-with
  [7]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#how-is-the-final-error-output-object-formed
  [8]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#basic-example
  [9]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#providing-multiple-possible-values
  [10]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#wildcards
  [11]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#array-wildcards
  [12]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#___or
  [13]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#___array_index
  [14]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#math-operations-wildcards
  [15]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#___bt
  [16]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#___eq
  [17]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#___gt
  [18]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#___lt
  [19]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#hash-wildcards
  [20]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#___
  [21]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#___optional
  [22]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#how-to-contribute
  [23]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine#license
  [24]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/blob/master/lib/monitor_engine/alert_helper.rb
  [25]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/blob/master/lib/monitor_engine/monitor_engine.rb#L18
  [26]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/blob/master/lib/monitor_engine/monitor_engine.rb
  [27]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/blob/master/lib/monitor_engine/alert.rb#L7
  [28]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/blob/master/lib/monitor_engine/alert.rb