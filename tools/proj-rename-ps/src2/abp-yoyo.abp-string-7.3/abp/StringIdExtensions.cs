using JetBrains.Annotations;

using System;
using System.Collections.Generic;
using System.Text;

namespace Abp
{
    public static class StringIdExtensions
    {
        public static bool HasValue(this string val)
        {
            return !string.IsNullOrWhiteSpace(val);
        }
    }
}
