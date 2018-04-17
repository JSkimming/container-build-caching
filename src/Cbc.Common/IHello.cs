// Copyright (c) 2018 James Skimming. All rights reserved.

namespace Cbc
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Threading;
    using System.Threading.Tasks;

    /// <summary>
    /// Say hello.
    /// </summary>
    public interface IHello
    {
        /// <summary>
        /// Gets a message for a name.
        /// </summary>
        /// <param name="name">A name.</param>
        /// <param name="cancellationToken">A <see cref="CancellationToken" /> to observe while waiting for a task to
        /// complete.</param>
        /// <returns>A nice message.</returns>
        Task<string> GetMessageAsync(string name, CancellationToken cancellationToken = default);
    }
}
