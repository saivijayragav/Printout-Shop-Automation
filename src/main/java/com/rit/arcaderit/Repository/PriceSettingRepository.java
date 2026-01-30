package com.rit.arcaderit.Repository;

import com.rit.arcaderit.Entity.PriceSetting;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface PriceSettingRepository extends JpaRepository<PriceSetting, String> {
    // JpaRepository provides all the methods your Service needs:
    // .findById(String id)
    // .save(PriceSetting entity)
    // .existsById(String id)
}