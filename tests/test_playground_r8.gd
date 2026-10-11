extends RefCounted
## Playground R8 — prueba compatible con tests/run_tests.gd

func run(t) -> void:
    var loaded := 0
    for id in PlaygroundManifest.SETS:
        var aset: AnimSet = AssetCatalog.anim_set(str(id))
        t.check(aset != null, "R8 carga: " + str(id))
        if aset == null:
            continue
        loaded += 1
        t.check(aset.has_anim("idle"), "R8 idle: " + str(id))
        for clip in aset.anim_names():
            t.check(
                aset.frame_count(clip, "south") > 0,
                "R8 cuadros: %s/%s" % [id, clip]
            )
            t.check(
                aset.first_texture(clip) != null,
                "R8 textura: %s/%s" % [id, clip]
            )
    t.eq(loaded, 12, "12 diseños R8 cargados")
    for id in PlaygroundProfiles.LOOKS:
        var profile: Dictionary = PlaygroundProfiles.enemy(str(id))
        t.check(not profile.is_empty(), "R8 perfil: " + str(id))
