# ChilaSeda - Weight Fixes (B42) 2.1.1

This package contains VanillaWeightFix and the Any Wall Flags and Posters
weight overrides. Weight Monitor now belongs to `ChilaSeda_AuditSuite_B42`.

VanillaWeightFix targets `Base.Magazine_Rich` (`“Alto Volador”`) at 0.10 kg.
This is a reasoned estimate from comparable printed magazines; the matching
Weight Monitor target and evidence are documented in `docs/Manual_Pesos_B42_y_Monitor.md`.

Machete targets now cover `Base.Machete` and `Base.Machete_Crude` at 0.71 kg,
and the unfinished `Base.MacheteBlade_NoTang` at 0.48 kg. These estimates use
the UNIDO fabrication reference for a 0.71 kg complete machete and 0.48 kg
machete body. They are mirrored in Weight Monitor 1.9.8 and documented in
`docs/Manual_Pesos_B42_y_Monitor.md`.

`TrueWeight`, `ThisIsYourLife`, `ExtendedVanillaWeapons`,
`AnimalRemasterApproved`, `DGVFlags`, and `DGVPosters` are optional. The fixes
scan loaded item definitions, so missing target mods are ignored. No hard
requirements are declared. See `docs/Manual_Pesos_B42_y_Monitor.md` for targets and
evidence.
