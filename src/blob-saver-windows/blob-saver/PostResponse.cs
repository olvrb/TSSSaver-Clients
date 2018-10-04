using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace blob_saver {
    class PostResponse {
        public PostResponse(bool success, string url) {
            this.Success = success;
            this.Url = url;
        }
        public bool Success { get; }
        public string Url { get; }
        public override string ToString() {
            return this.Url;
        }
    }
}
