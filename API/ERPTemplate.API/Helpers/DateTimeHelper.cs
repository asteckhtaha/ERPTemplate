namespace ERPTemplate.API.Helpers;

/// <summary>
/// Project-wide standard for date/time. Everything is UTC.
/// </summary>
public static class DateTimeHelper
{
    public static DateTime UtcNow => DateTime.UtcNow;

    public static DateTimeOffset UtcNowOffset => DateTimeOffset.UtcNow;

    public static DateTime UtcToday => DateTime.UtcNow.Date;

    public static DateTime ToUtc(DateTime value)
    {
        return value.Kind switch
        {
            DateTimeKind.Utc => value,
            DateTimeKind.Local => value.ToUniversalTime(),
            _ => DateTime.SpecifyKind(value, DateTimeKind.Utc)
        };
    }

    public static DateTime? ToUtc(DateTime? value)
        => value.HasValue ? ToUtc(value.Value) : null;

    public static DateTime ToLocal(DateTime utcValue, TimeZoneInfo timeZone)
    {
        ArgumentNullException.ThrowIfNull(timeZone);

        var utc = utcValue.Kind == DateTimeKind.Utc
            ? utcValue
            : DateTime.SpecifyKind(utcValue, DateTimeKind.Utc);

        return TimeZoneInfo.ConvertTimeFromUtc(utc, timeZone);
    }
}
