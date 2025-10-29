














video_offsets   dw 350 dup(?)



mul100_table    dw 100 dup(?)



tile_walkable   db 256 dup(1)







jugador_up_a_mask       db 128 dup(0)
jugador_up_b_mask       db 128 dup(0)
jugador_down_a_mask     db 128 dup(0)
jugador_down_b_mask     db 128 dup(0)
jugador_izq_a_mask      db 128 dup(0)
jugador_izq_b_mask      db 128 dup(0)
jugador_der_a_mask      db 128 dup(0)
jugador_der_b_mask      db 128 dup(0)



sprite_grass1_mask      db 32 dup(0)
sprite_path_mask        db 32 dup(0)
sprite_water_mask       db 32 dup(0)
sprite_tree_mask        db 32 dup(0)
sprite_sand_mask        db 32 dup(0)
sprite_rock_mask        db 32 dup(0)
sprite_snow_mask        db 32 dup(0)
sprite_ice_mask         db 32 dup(0)
sprite_wall_mask        db 32 dup(0)
sprite_fortress_mask    db 32 dup(0)
sprite_dirt_mask        db 32 dup(0)
sprite_lava_mask        db 32 dup(0)
sprite_bridge_mask      db 32 dup(0)

sprite_cristal_mask     db 32 dup(0)
sprite_gema_mask        db 32 dup(0)
sprite_moneda_mask      db 32 dup(0)

sprite_heart_full_mask  db 32 dup(0)
sprite_heart_empty_mask db 32 dup(0)








dirty_tiles     db 10000 dup(0)


frame_counter   db 0




