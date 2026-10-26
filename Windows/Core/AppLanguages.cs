namespace LocalRouteLauncher;

public static class AppLanguages
{
    public static readonly string[] Codes = ["en", "zh-CN", "zh-TW", "ru", "fa", "be", "es", "ar", "pt"];
    public static readonly string[] Labels = ["English", "简体中文", "繁體中文", "Русский", "فارسی", "Беларуская", "Español", "العربية", "Português"];
    public static bool IsRightToLeft(string code) => code is "fa" or "ar";

    public static string Resolve(string preference)
    {
        var code = preference.ToLowerInvariant().Replace('_', '-');
        var subtags = code.Split('-');
        if (subtags[0] == "zh")
        {
            if (subtags.Contains("hans")) return "zh-CN";
            if (subtags.Contains("hant")) return "zh-TW";
            return subtags.Any(part => part is "tw" or "hk" or "mo") ? "zh-TW" : "zh-CN";
        }
        foreach (var supported in Codes)
            if (code == supported.ToLowerInvariant() || code.StartsWith(supported.ToLowerInvariant() + "-", StringComparison.Ordinal))
                return supported;
        return "en";
    }
}
