using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Coupon.API
{
    public class ExceptionTrigger : Dictionary<string, int>
    {
        public (bool configured, string message, bool shouldFire) Process(string code)
        {
            const string setTriggerPrefix = "FAIL ";

            lock (this)
            {
                if (code.StartsWith(setTriggerPrefix))
                {
                    var tokens = code.Split(' ', StringSplitOptions.RemoveEmptyEntries);

                    TryAdd(tokens[2], Convert.ToInt32(tokens[1]));

                    return (true, $"{tokens[1]} failure(s) configured for code \"{tokens[2]}\"!", false);
                }

                if (TryGetValue(code, out int current))
                {
                    if (--current < 0)
                    {
                        Remove(code);

                        return (false, null, false);
                    }

                    this[code] = current;

                    return (false, null, true);
                }
                else
                {
                    return (false, null, false);
                }

            }
        }
    }

}
