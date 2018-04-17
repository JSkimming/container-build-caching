// Copyright (c) 2018 James Skimming. All rights reserved.

namespace Cbc
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Threading;
    using System.Threading.Tasks;

    /// <inheritdoc />
    public class Hello : IHello
    {
        /// <inheritdoc />
        public Task<string> GetMessageAsync(string name, CancellationToken cancellationToken = default)
        {
            return Task.FromResult($"Hello there {name}.");
        }
    }
}
