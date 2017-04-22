local EC  = RegisterMod('Exposive Chests', 1)
local EXPLOSIVE_CHESTS = Isaac.GetItemIdByName('Explosive Chests')

function is_a_chest(entity)
  if entity.Type ~= EntityType.ENTITY_PICKUP then return false end

  Isaac.RenderText(entity.Variant, 40, 40, 0, 255, 0, 255)

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
            Game():BombExplosionEffects(
              chest.Position, 10, player.TearFlags, player.TearColor,
              chest, 1, false, false
            )
            chest:Remove()

            return
          end
        end
      end
    end
  end
end

EC:AddCallback(ModCallbacks.MC_POST_UPDATE, EC.explodeChests)
