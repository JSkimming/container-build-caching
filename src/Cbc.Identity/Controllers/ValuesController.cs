// Copyright (c) 2018 James Skimming. All rights reserved.

namespace Cbc.Identity.Controllers
{
    using System;
    using System.Collections.Generic;
    using System.Threading.Tasks;
    using Microsoft.AspNetCore.Authorization;
    using Microsoft.AspNetCore.Mvc;

    /// <summary>
    /// A simple test controller to be deleted once further controllers are added.
    /// </summary>
    [Produces("application/json")]
    [Consumes("application/json")]
    [Route("api/[controller]")]
    public class ValuesController : Controller
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="ValuesController"/> class.
        /// </summary>
        public ValuesController()
        {
        }

        /// <summary>
        /// Gets the test values.
        /// </summary>
        /// <returns>The test values.</returns>
        /// <remarks><code>
        /// GET: api/values
        /// </code></remarks>
        [HttpGet]
        public async Task<IEnumerable<string>> GetAsync()
        {
            await Task.Yield();
            await Task.Delay(10).ConfigureAwait(false);
            return new[] { "value1", "value2" };
        }

        /// <summary>
        /// Gets the test value by Id
        /// </summary>
        /// <param name="id">The id of the value.</param>
        /// <returns>The test value.</returns>
        /// <remarks><code>
        /// GET api/values/5
        /// </code></remarks>
        [HttpGet("{id}")]
        public string Get(int id)
        {
            return "value" + id;
        }

        /// <summary>
        /// Posts the test value.
        /// </summary>
        /// <param name="value">The test value.</param>
        /// <remarks><code>
        /// POST api/values
        /// </code></remarks>
        [HttpPost]
        public void Post([FromBody]string value)
        {
        }

        /// <summary>
        /// Puts the test value.
        /// </summary>
        /// <param name="id">The id of the value.</param>
        /// <param name="value">The test value.</param>
        /// <remarks><code>
        /// PUT api/values/5
        /// </code></remarks>
        [HttpPut("{id}")]
        public void Put(int id, [FromBody]string value)
        {
        }

        /// <summary>
        /// Deletes the test value.
        /// </summary>
        /// <param name="id">The id of the value.</param>
        /// <remarks><code>
        /// DELETE api/values/5
        /// </code></remarks>
        [HttpDelete("{id}")]
        public void Delete(int id)
        {
        }
    }
}
