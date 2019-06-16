require Cldr.Calendar.Compiler.Week

defmodule Cldr.Calendar.CSCO do
  use Cldr.Calendar.Base.Week,
    min_days_in_first_week: 7,
    first_or_last: :last,
    first_day_of_year: 6,
    first_month_of_year: 7
end
