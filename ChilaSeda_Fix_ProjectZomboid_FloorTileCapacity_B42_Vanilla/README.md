ChilaSeda Fix - Project Zomboid Floor Tile Capacity (B42)

<div align="center">

[🏠 Repo](../README.md) · [🤝 Contribuir](../CONTRIBUTING.md) · [🚀 Releases](../docs/releases/README.md)

</div>

---


This local fix changes the virtual floor inventory container used by the inventory UI
from the vanilla 50 weight units to 1000. The value is the upper end of the range
requested for the note titled “Ajuste de límite de peso en el suelo / celdas”.

It wraps ISInventoryPage.GetFloorContainer and applies ItemContainer:setCapacity(1000)
to the returned floor container. The official B42 API exposes setCapacity(int); local
Jill validation is still needed to confirm actual transfers and behavior at 1000.
