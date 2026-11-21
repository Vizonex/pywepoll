import pytest

from wepoll import new_event_loop


@pytest.fixture(
    params=[
        pytest.param(
            ("asyncio", {"loop_factory": new_event_loop}),
            id="asyncio[wepoll]",
        )
    ]
)
def anyio_backend(request: pytest.FixtureRequest):
    return request.param


@pytest.mark.anyio
@pytest.mark.xfail(reason="Cyares has been disabled until 3.15 support is avalible.")
async def test_dns_resolver_over_wepoll() -> None:
    from cyares.aio import DNSResolver
    async with DNSResolver(["8.8.8.8", "8.8.4.4"], event_thread=False) as dns:
        assert await dns.query("google.com", "A")
