local EC = RegisterMod('Parcel bomb', 1)
local PARCEL_BOMB = Isaac.GetItemIdByName('Parcel bomb')

log_text = ''

function log()
  Isaac.RenderText(log_text, 40, 40, 0, 255, 0, 255)
end

function isColinear(Vector1, Vector2, angle)
  local dotProd = Vector1:Normalized():Dot(Vector2:Normalized())

  log_text = dotProd

  return (
    dotProd <= 1 + angle and
    dotProd >= 1 - angle
  )
end

function isChest(entity)
  if entity.Type ~= EntityType.ENTITY_PICKUP then return false end

  if (
    entity.Variant ~= PickupVariant.PICKUP_CHEST and
    entity.Variant ~= PickupVariant.PICKUP_BOMBCHEST and
    entity.Variant ~= PickupVariant.PICKUP_SPIKEDCHEST and
    entity.Variant ~= 54 and  -- Mimic
    entity.Variant ~= PickupVariant.PICKUP_ETERNALCHEST and
    entity.Variant ~= PickupVariant.PICKUP_LOCKEDCHEST and
    entity.Variant ~= PickupVariant.PICKUP_REDCHEST
  ) then return false end

  if entity.SubType ~= ChestSubType.CHEST_CLOSED then return false end

  return true
end

function spawnExplodingMiniChest(parent)
  -- Make a bomb and skin them like the parent entity.
  -- We should consider doing this the other way round
  local random_position = parent.Position:__add(
    Vector(25,0):Rotated(math.random(360))
  )

  local bomb = Isaac.Spawn(
    EntityType.ENTITY_BOMBDROP,
    BombVariant.BOMB_NORMAL,
    BombSubType.BOMB_NORMAL,
    random_position,
    Vector (0, 0),
    parent
  ):ToBomb()

  -- Little bomb!
  bomb.ExplosionDamage = 0.5
  bomb.RadiusMultiplier = 0.5
  bomb.SpriteScale = Vector(0.5, 0.5)

  -- Take advantage of Glitter Bomb mechanics to make them like little chests
  bomb.Flags = bomb.Flags + TearFlags.TEAR_GLITTER_BOMB

  -- Swap out the sprites
  local parent_sprite = parent:GetSprite()
  local bomb_sprite = bomb:GetSprite()
  bomb_sprite:Stop()
  bomb_sprite:Load(parent_sprite:GetFilename(), true)
  bomb_sprite:Play(parent_sprite:GetDefaultAnimationName())
end

function EC:explodeChest(chest)
  local player = Isaac.GetPlayer(0);

  -- Open the chest
  chest:TryOpenChest()

  -- Explode!
  local bombflags = player:GetBombFlags()
  Game():BombExplosionEffects(
    chest.Position, 10, bombflags, player.TearColor,
    chest, 1, false, false
  )
  chest:Remove()

  -- Scatter bomb synergy
  if (bombflags &  TearFlags.TEAR_SCATTER_BOMB ~= 0) then
    spawnExplodingMiniChest(chest)
    spawnExplodingMiniChest(chest)
    spawnExplodingMiniChest(chest)
  end
end

function EC:postUpdate()
  local player = Isaac.GetPlayer(0);
  local entities = Isaac.GetRoomEntities();

  log()

  if (player:HasCollectible(PARCEL_BOMB) ~= true) then return end

  for _, entity in pairs(entities) do
    if (
      entity.Type == EntityType.ENTITY_TEAR or
      entity.Type == EntityType.ENTITY_LASER
    ) then
      local projectile = entity

      for _, entity in pairs(entities) do
        if (isChest(entity)) then
          local chest = entity:ToPickup()

          if projectile.Type == EntityType.ENTITY_TEAR then
            if projectile.Position:Distance(chest.Position) < 30 then
              Game():SpawnParticles(projectile.Position, EffectVariant.TEAR_POOF_B, 1, 1, player.TearColor, 0)
              projectile:Remove()

              EC:explodeChest(chest)

              -- For tears, we don't have any need to continue after this point
              return
            end
          end

          if projectile.Type == EntityType.ENTITY_LASER then
            local playerPos = player.Position + Vector(0, -5)
            local laser = projectile:ToLaser()

            local vectorPlayerChest = chest.Position - playerPos
            local vectorPlayerLaser = laser:GetEndPoint() - playerPos

            local isPiercing =  laser.OneHit == false or player.TearFlags &  TearFlags.TEAR_PIERCING ~= 0

            -- Work properly with piercing  and non-piercing lasers
            local willIntercept
            if laser.MaxDistance == 0 and isPiercing then
              willIntercept = true
            else
              local distancePlayerLaser = laser.MaxDistance

              if laser.MaxDistance == 0 then
                local laserTarget = Game():GetRoom():GetLaserTarget(
                  playerPos, -- + Vector(0, -10),
                  vectorPlayerLaser
                )
                distancePlayerLaser = laserTarget:Distance(playerPos)
              end

              local distancePlayerChest = chest.Position:Distance(playerPos)

              willIntercept = distancePlayerLaser >= distancePlayerChest
            end

            if (
              willIntercept and
              isColinear(vectorPlayerChest, vectorPlayerLaser, 0.015)
            ) then
              EC:explodeChest(chest)
            end
          end
        end
      end
    end
  end
end

EC:AddCallback(ModCallbacks.MC_POST_UPDATE, EC.postUpdate)
