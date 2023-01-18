SELECT 
			    IF(orders.isconfidential IS TRUE,1,0) AS order_confidential,
			     ref_productlistgeneric.`no_specimen_label`,
				  GROUP_CONCAT(
				    DISTINCT cyto_record_staining.cyto_order_staining_id
				  ) AS cyto_order_staining_id,
				  COUNT(
				    DISTINCT IF(
				      cyto_record_staining.process_main_status = '6503',
				      cyto_record_staining.`order_products_id`,
				      NULL
				    )
				  ) AS submittedSlide,
				  COUNT(
				    DISTINCT IF(
				      product_specimens.specimen_prepared IS NULL,
				      IF(
				        ref_materialtype.code = 'stained_slide',
				        product_specimens.`order_products_id`,
				        NULL
				      ),
				      NULL
				    )
				  ) AS receivedStainedSlide,
				  COUNT(
				    DISTINCT IF(
				      product_specimens.ref_stainname_id IS NOT NULL,
				      IF(
				        ref_materialtype.code = 'stained_slide',
				        product_specimens.`order_products_id`,
				        NULL
				      ),
				      NULL
				    )
				  ) AS histoStainedSlide,
				  GROUP_CONCAT(
				    DISTINCT product_specimens.batch_no
				  ) AS batch_no,
				  GROUP_CONCAT(DISTINCT ref_staintype.`code`) AS ref_staintype_code,
				  GROUP_CONCAT(
				    DISTINCT ref_generic_dataset.`generic_code`
				  ) AS generic_code,
				  IFNULL(
				    GROUP_CONCAT(
				      DISTINCT order_products.`accession`
				    ),
				    GROUP_CONCAT(
				      product_specimens.`accession_no`
				    )
				  ) AS accession_no,
				  haema_slide_prep.haema_slide_prep_id,
				  order_products.`unit_code`,
				  IF(
				    order_products.`ref_priority_id` != 2,
				    0,
				    1
				  ) AS isurgent_order,
				  IF(orders.`isfpp` = 1, 1, 0) AS isfpp_order,
				  order_products.`order_products_id`,
				  GROUP_CONCAT(
				    DISTINCT product_specimens.product_specimens_id
				  ) AS product_specimens_id,
				   IFNULL(GROUP_CONCAT(DISTINCT IF((product_specimens.isdeleted IS NULL OR product_specimens.isdeleted=''), product_specimens.`slide_no`,"")),haema_slide_prep.`slideLabel`) AS slide_no,
				  GROUP_CONCAT(
				    DISTINCT product_specimens.specimen_no
				  ) AS specimen_no,
				  order_products.`lab_no`,
				  GROUP_CONCAT(
				    DISTINCT ref_specimentype.`name`
				  ) AS specimen_type,
				  GROUP_CONCAT(
				    DISTINCT ref_anatomicalsite.`name`
				  ) AS anatomical_site,
				  GROUP_CONCAT(
				    DISTINCT ref_specimensite.`name`
				  ) AS specimen_site,
				  GROUP_CONCAT(
				    DISTINCT ref_materialtype.`name`
				  ) AS material_type,
				  GROUP_CONCAT(
				    DISTINCT ref_product.`short_name`
				  ) AS test_name,
				  orders.`order_no` AS `order_no`,
				  CASE
				    WHEN users_view.view_confidential IS FALSE 
				    AND orders.isconfidential IS TRUE 
				    THEN "****" 
				    WHEN users_view.view_confidential IS TRUE 
				    THEN IF(
				      orders.isexternal IS FALSE,
				      `patients`.`mrn_internal`,
				      patients.`registration_no`
				    ) 
				    ELSE IF(
				      orders.isexternal IS FALSE,
				      `patients`.`mrn_internal`,
				      patients.`registration_no`
				    ) 
				  END mrn,
				  CASE
				    WHEN users_view.view_confidential IS FALSE 
				    AND orders.isconfidential IS TRUE 
				    THEN "****" 
				    WHEN users_view.view_confidential IS TRUE 
				    THEN IF(
				      GROUP_CONCAT(
				        DISTINCT `product_collection_details`.`env_machine_name`
				      ) IS NULL,
				      CONCAT(
				        `patients`.`full_name`,
				        "\n",
				        patients.`patient_id_no`
				      ),
				      CONCAT(
				        GROUP_CONCAT(
				          DISTINCT `product_collection_details`.`env_machine_name`
				        ),
				        "\n",
				        GROUP_CONCAT(
				          DISTINCT `product_collection_details`.`env_custom_id`
				        )
				      )
				    ) 
				    ELSE IF(
				      GROUP_CONCAT(
				        DISTINCT `product_collection_details`.`env_machine_name`
				      ) IS NULL,
				      CONCAT(
				        `patients`.`full_name`,
				        "\n",
				        patients.`patient_id_no`
				      ),
				      CONCAT(
				        GROUP_CONCAT(
				          DISTINCT `product_collection_details`.`env_machine_name`
				        ),
				        "\n",
				        GROUP_CONCAT(
				          DISTINCT `product_collection_details`.`env_custom_id`
				        )
				      )
				    ) 
				  END name_id,
				  registered_status.created_date AS registered_date,
				  ref_product.`non_patientbased` AS isEnviro,
				  CASE 
					WHEN share_test.share_order_products_id IS NOT NULL THEN CONCAT(order_products.order_products_id, ",", share_test.share_order_products_id)
					ELSE order_products.order_products_id
				  END AS all_order_products_id
				FROM
				  product_specimens 
				  LEFT JOIN product_specimens slide_specimen 
				    ON slide_specimen.order_products_id = product_specimens.`order_products_id` 
				    AND slide_specimen.isactive =1
				    
				  JOIN order_products 
				    ON order_products.`order_products_id` = product_specimens.order_products_id
				     AND order_products.isactive =1
				        
				  JOIN orders 
				    ON order_products.`orders_id` = orders.`orders_id`
				    AND orders.isactive =1
				  LEFT JOIN (
					  SELECT
						order_products.share_with_test_id,
						GROUP_CONCAT(order_products.order_products_id SEPARATOR ',') AS share_order_products_id
					  FROM
						order_products
					  LEFT JOIN ref_product ON (order_products.ref_product_id = ref_product.ref_product_id)
					
					  WHERE
					      order_products.share_with_test_id IS NOT NULL
					  AND ISNULL(order_products.product_parent_id)
					  AND order_products.issharing = 1
					
					  GROUP BY order_products.share_with_test_id
				  ) share_test ON share_test.share_with_test_id = order_products.order_products_id 
				  LEFT JOIN patients 
				    ON patients.`patients_id` = orders.`patients_id` 
				   AND patients.isactive = 1 
				  LEFT JOIN `ref_specimentype` 
				ON (ref_specimentype.`ref_specimentype_id` = product_specimens.`ref_specimentype_id`)
				 LEFT JOIN `ref_anatomicalsite` 
				    ON `product_specimens`.`ref_anatomicalsite_id` = `ref_anatomicalsite`.`ref_anatomicalsite_id` 
				  LEFT JOIN `ref_specimensite` 
				    ON `ref_specimensite`.`ref_specimensite_id` = product_specimens.`ref_specimensite_id` 
				  LEFT JOIN `ref_materialtype` 
				    ON ref_materialtype.`ref_materialtype_id` = product_specimens.`ref_materialtype_id` 
				  LEFT JOIN ref_product 
				    ON ref_product.`ref_product_id` = `order_products`.`ref_product_id` 
				    AND ref_product.isactive = 1
				
				  /*LEFT JOIN report 
				    ON report.`order_products_id` = order_products.`order_products_id` */
				  LEFT JOIN `product_collection_details` 
				    ON `product_collection_details`.`product_collection_details_id` = `product_specimens`.`product_collection_details_id` 
				  LEFT JOIN product_trackings registered_status 
				    ON registered_status.order_products_id = order_products.`order_products_id` 
				    AND registered_status.isdeleted = 0 
				    AND registered_status.product_status_id = 1000 
				    AND registered_status.isactive=1
				  LEFT JOIN ref_generic_dataset 
				    ON product_specimens.`ref_specimencategory_code` = ref_generic_dataset.`generic_code` 
				    AND `ref_generic_dataset`.`isactive` = '1'
				  LEFT JOIN ref_staintype 
				    ON ref_staintype.`ref_staintype_id` = product_specimens.`ref_staintype_id` 
				    AND ref_staintype.isactive= '1'
				  LEFT JOIN cyto_record_staining 
				    ON product_specimens.batch_no = cyto_record_staining.batch_no 
				    AND cyto_record_staining.isactive = 1
				  LEFT JOIN haema_slide_prep 
				    ON haema_slide_prep.`order_products_id` = order_products.`order_products_id` 
				    AND haema_slide_prep.`isactive` = 1 
				  LEFT JOIN haema_slide_prep_detail 
				    ON haema_slide_prep_detail.`haema_slide_prep_id` = haema_slide_prep.`haema_slide_prep_id` 
				    AND haema_slide_prep_detail.`isactive` = 1 
				 JOIN `ref_productlistgeneric` 
				     ON `ref_productlistgeneric`.`ref_product_id` = order_products.`ref_product_id`
				     AND ref_productlistgeneric.isactive = 1
				  CROSS JOIN 
				    (SELECT 
				      `tbl_user_detail`.`user_id` AS `user_id`,
				      IF(
				        ISNULL(
				          `tbl_user_detail`.`view_confidential`
				        ),
				        FALSE,
				        `tbl_user_detail`.`view_confidential`
				      ) AS `view_confidential`,
				      `tbl_user`.`username` AS `username` 
				    FROM
				      (
				        `tbl_user` 
				        LEFT JOIN `tbl_user_detail` 
				          ON (
				            (
				              `tbl_user_detail`.`user_id` = `tbl_user`.`user_id`
				            )
				          )
				      )) `users_view` 
				WHERE product_specimens.isactive = 1
				   AND (product_specimens.created_by != "wpd" OR product_specimens.created_by IS NULL)
				   AND order_products.created_by != "wpd"
				   AND orders.created_by != "wpd"
				   AND ((users_view.username = 'muham5701' AND users_view.username IS NOT NULL)) 
				GROUP BY order_products.`order_products_id`,
				  users_view.view_confidential,
				  registered_status.product_trackings_id,
				  haema_slide_prep.haema_slide_prep_id,
  				  ref_productlistgeneric.no_specimen_label,
  				  share_test.share_order_products_id\G
