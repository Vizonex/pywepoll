from wepoll import WepollEventLoop
from cyares.aio import DNSResolver
import pytest

import anyio


@pytest.fixture(
    params=[pytest.param(("asyncio", {"loop_factory": WepollEventLoop}), id="asyncio[WepollEventLoop]")]
)
def anyio_backend(request: pytest.FixtureRequest):
    return request.param

@pytest.mark.anyio
async def test_dns_resolver_over_wepoll(anyio_backend):
    async with DNSResolver(["8.8.8.8", "8.8.4.4"], event_thread=False) as dns:
        assert await dns.query("google.com", "A") 


