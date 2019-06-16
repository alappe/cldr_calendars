defmodule Cldr.Calendar.Config do
  @moduledoc """
  Defines the configuration for a calendar.

  """
  defstruct calendar: nil,

            # Locale can be used to derive
            # the :first_day and :min_days
            locale: nil,

            # A default backend for this
            # calendar
            cldr_backend: nil,

            # Each quarter has three
            # 'months` each of 13 weeks
            # in either of a 4,4,5; 4,5,4
            # of 5,4,4 layout
            weeks_in_month: [4, 4, 5],

            # Indicates if the anchor
            # represents the beginning
            # of the year or the end
            begins_or_ends: :begins,

            # Calendar begins on the
            # :first, :last or :nearest
            first_or_last: :first,

            # Year begins on this day
            # Use :first to mean the day
            # day of the week on which the
            # first day of the year occurs
            # The functions `Cldr.Calendar.monday()`
            # etc can be used
            first_day_of_year: 1,

            # Year begins in this Gregorian month
            first_month_of_year: 1,

            # The year of the last_day or first_day
            # is either the year with the :majority
            # of months or the :beginning year
            # or :ending year
            year: :majority,

            # First week has at least
            # this many days in current
            # year
            min_days_in_first_week: 7

  @typedoc """
  Defines the struct type for a calendar configuration
  """
  @type t() :: %__MODULE__{
          calendar: Cldr.Calendar.calendar() | nil,
          locale: Cldr.Locale.locale_name() | Cldr.LanguageTag.t() | nil,
          cldr_backend: Cldr.backend() | nil,
          weeks_in_month: list(pos_integer()),
          begins_or_ends: :begins | :ends,
          first_or_last: :first | :last,
          first_day_of_year: Cldr.Calendar.day_of_week(),
          first_month_of_year: pos_integer(),
          year: :majority | :starts | :ends,
          min_days_in_first_week: 1..7
        }

  @doc false
  def extract_options(options) do
    invalidate_old_options!(options)
    detect_invalid_options!(options)
    backend = Keyword.get(options, :backend)
    locale = Keyword.get(options, :locale, Cldr.get_locale())
    calendar = Keyword.get(options, :calendar)
    first_or_last = Keyword.get(options, :first_or_last, :first)
    begins_or_ends = Keyword.get(options, :begins_or_ends, :begins)
    weeks_in_month = Keyword.get(options, :weeks_in_month, [4, 5, 4])
    year = Keyword.get(options, :year, :majority)
    month = Keyword.get(options, :first_month_of_year, 1)
    {min_days, day} = min_and_first_days(locale, options)

    %__MODULE__{
      min_days_in_first_week: min_days,
      first_day_of_year: day,
      first_month_of_year: month,
      year: year,
      cldr_backend: backend,
      calendar: calendar,
      first_or_last: first_or_last,
      begins_or_ends: begins_or_ends,
      weeks_in_month: weeks_in_month
    }
  end

  defp min_and_first_days(_locale, options) do
    min_days = Keyword.get(options, :min_days_in_first_week, 7)
    first_day = Keyword.get(options, :first_day_of_year, 1)
    {min_days, first_day}
  end

  @valid_weeks_in_month [[4, 4, 5], [4, 5, 4], [5, 4, 4]]
  @valid_year [:majority, :beginning, :ending]

  @doc false
  def validate_config(config, calendar_type) do
    with :ok <-
           validate_day(config, calendar_type),
         :ok <-
           assert(config.first_month_of_year in 1..12, month_error(config.first_month_of_year)),
         :ok <-
           assert(config.year in @valid_year, year_error(config.year)),
         :ok <-
           assert(
             config.min_days_in_first_week in 1..7,
             min_days_for_locale_error(config.min_days_in_first_week)
           ),
         :ok <-
           assert(
             config.first_or_last in [:first, :last],
             first_or_last_error(config.first_or_last)
           ),
         :ok <-
           assert(
             config.begins_or_ends in [:begins, :ends],
             begins_or_ends_error(config.begins_or_ends)
           ),
         :ok <-
           assert(
             config.weeks_in_month in @valid_weeks_in_month,
             weeks_in_month_error(config.weeks_in_month)
           ) do
      {:ok, config}
    end
  end

  @doc false
  def validate_config!(config, calendar_type) do
    case validate_config(config, calendar_type) do
      {:ok, config} -> config
      {:error, message} -> raise ArgumentError, message
    end
  end

  defp invalidate_old_options!(options) do
    if options[:day],
      do: raise(ArgumentError, "Option :day is replaced with :first_day_of_year")

    if options[:month],
      do: raise(ArgumentError, "Option :month is replaced with :first_month_of_year")

    if options[:min_days],
      do: raise(ArgumentError, "Option :min_days is replaced with :min_days_in_first_week")
  end

  def valid_options do
    Map.keys(%__MODULE__{})
  end

  def detect_invalid_options!(options) do
    case Enum.filter(options, &(&1 in valid_options())) do
      [] ->
        options

      invalid_options ->
        raise ArgumentError,
              "Invalid options #{inspect(invalid_options)} found.  Valid options are #{
                inspect(valid_options())
              }"
    end
  end

  defp validate_day(config, :week) do
    assert(config.first_day_of_year in 1..7, day_error(config.first_day_of_year))
  end

  defp validate_day(config, :month) do
    assert(
      config.first_day_of_year in 1..7 or config.first_day_of_year == :first,
      day_error(config.first_day_of_year)
    )
  end

  defp assert(true, _) do
    :ok
  end

  defp assert(false, message) do
    {:error, message}
  end

  defp day_error(day) do
    ":first_day_of_year must be in the range 1..7. Found #{inspect(day)}."
  end

  defp month_error(month) do
    ":first_month_of_year must be in the range 1..12. Found #{inspect(month)}."
  end

  defp year_error(year) do
    ":year must be either :beginning, :ending or :majority. Found #{inspect(year)}."
  end

  defp min_days_for_locale_error(min_days) do
    ":min_days_in_first_week must be in the range 1..7. Found #{inspect(min_days)}."
  end

  defp first_or_last_error(first_or_last) do
    ":first_or_last must be :first or :last. Found #{inspect(first_or_last)}."
  end

  defp begins_or_ends_error(begins_or_ends) do
    ":begins_or_ends must be :begins or :ends. Found #{inspect(begins_or_ends)}."
  end

  defp weeks_in_month_error(weeks_in_month) do
    ":weeks_in_month must be [4,4,5], [4,5,4] or [5,4,4]. Found #{inspect(weeks_in_month)}"
  end
end
