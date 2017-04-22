local EC = RegisterMod('Exposive Chests', 1)
local EXPLOSIVE_CHESTS = Isaac.GetItemIdByName('Explosive Chests')

function is_a_chest(entity)
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

  return true
end

function spawn_mini_chest(parent)
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

  bomb.ExplosionDamage = 0.5
  bomb.RadiusMultiplier = 0.5
  bomb.Flags = bomb.Flags + TearFlags.TEAR_GLITTER_BOMB

  bomb.SpriteScale = Vector(0.5, 0.5)

  local parent_sprite = parent:GetSprite()
  local bomb_sprite = bomb:GetSprite()

  bomb_sprite:Load(parent_sprite:GetFilename(), true)
  bomb_sprite:Play(parent_sprite:GetDefaultAnimationName())
end

function EC:explodeChests()
  local player = Isaac.GetPlayer(0);
  local entities = Isaac.GetRoomEntities();

  if (player:HasCollectible(EXPLOSIVE_CHESTS) ~= true) then return end

  for _, entity in pairs(entities) do
    if (entity.Type == EntityType.ENTITY_TEAR) then
      local tear = entity

      for _, entity in pairs(entities) do
        if (is_a_chest(entity)) then
          local chest = entity:ToPickup()

          if tear.Position:Distance(chest.Position) < 30 then
            -- Kill the tear
            Game():SpawnParticles(tear.Position, EffectVariant.TEAR_POOF_B, 1, 1, player.TearColor, 0)
            tear:Remove()

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
              spawn_mini_chest(chest)
              spawn_mini_chest(chest)
              spawn_mini_chest(chest)
            end

            return
          end
        end
      end
    end
  end
end

EC:AddCallback(ModCallbacks.MC_POST_UPDATE, EC.explodeChests)
