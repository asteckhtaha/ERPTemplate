namespace ERPTemplate.API.Helpers
{
    /// <summary>
    /// One project-wide standard for date and time handling: <b>UTC everywhere</b>.
    /// Database columns are <c>DATETIME2(3)</c> and always store UTC; conversion to a user's local time
    /// happens only at the presentation layer.
    /// <para>Pure, stateless and safe for concurrent requests.</para>
    /// </summary>
    public static class DateTimeHelper
    {
        /// <summary>Current UTC date and time (kind = <see cref="DateTimeKind.Utc"/>).</summary>
        public static DateTime UtcNow => DateTime.UtcNow;

        /// <summary>Current UTC instant with offset information (use when an explicit offset is required, e.g. OAuth-style timestamps).</summary>
        public static DateTimeOffset UtcNowOffset => DateTimeOffset.UtcNow;

        /// <summary>Current UTC date only (for <c>DATE</c> columns).</summary>
        public static DateOnly UtcToday => DateOnly.FromDateTime(DateTime.UtcNow);

        /// <summary>
        /// Converts a value to UTC.
        /// <see cref="DateTimeKind.Local"/> is converted from the machine's local time;
        /// <see cref="DateTimeKind.Unspecified"/> is treated as already-UTC, because databases and JSON
        /// deserialization return UTC values without a kind.
        /// </summary>
        public static DateTime ToUtc(DateTime value) => value.Kind switch
        {
            DateTimeKind.Utc => value,
            DateTimeKind.Local => value.ToUniversalTime(),
            _ => DateTime.SpecifyKind(value, DateTimeKind.Utc)
        };

        /// <summary>
        /// Converts a stored UTC value into a specific time zone for display.
        /// Use only where a user-visible local time is genuinely required.
        /// </summary>
        public static DateTime ToTimeZone(DateTime utcValue, TimeZoneInfo timeZone)
        {
            ArgumentNullException.ThrowIfNull(timeZone);
            return TimeZoneInfo.ConvertTimeFromUtc(ToUtc(utcValue), timeZone);
        }
    }
}
