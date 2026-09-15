using Microsoft.Data.SqlClient;

namespace ERPTemplate.API.Helpers;

internal static class DataReaderExtensions
{
    public static bool IsDBNull(this SqlDataReader reader, string columnName)
        => reader.IsDBNull(reader.GetOrdinal(columnName));
}
