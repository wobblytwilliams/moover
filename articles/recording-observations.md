# Recording Observations

Training models requires an observation table describing behaviour
bouts.

## Required fields

The canonical observation schema is:

- `id`
- `label`
- `start_unix_ms`
- `end_unix_ms`

## Example

``` text
id,label,start_unix_ms,end_unix_ms
cow_1,grazing,1735689600000,1735689720000
cow_1,resting,1735689720000,1735689840000
```

## Notes

- Times should be in UTC Unix milliseconds.
- Each row should describe one labelled bout.
- `id` must match the animal identifier used in your training data.

## Alternative schemas

If your table uses different column names or ISO timestamps, you can map
them in the spec:

``` r
spec <- create_spec(
  schema = list(
    observations = list(
      id = "animal_id",
      label = "behaviour",
      start = "start_time",
      end = "end_time",
      time_format = "iso8601_utc"
    )
  )
)
```
