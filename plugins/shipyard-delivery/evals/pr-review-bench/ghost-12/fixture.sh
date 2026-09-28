#!/usr/bin/env bash
# Qodo PR-Review-Bench https://github.com/agentic-review-benchmarks/Ghost/pull/12 (MIT, see ../README.md).
set -e
cat > branch.diff <<'QODO_BENCH_DIFF_END'
diff --git a/ghost/core/core/server/data/tinybird/endpoints/api_kpis.pipe b/ghost/core/core/server/data/tinybird/endpoints/api_kpis.pipe
index e7aa395b4ff..24d904dd567 100644
--- a/ghost/core/core/server/data/tinybird/endpoints/api_kpis.pipe
+++ b/ghost/core/core/server/data/tinybird/endpoints/api_kpis.pipe
@@ -140,9 +140,6 @@ SQL >
                     {% if defined(date_to) %} and toDate(toTimezone(timestamp, {{String(timezone, 'Etc/UTC', description="Site timezone", required=True)}})) <= {{ Date(date_to) }} {% else %} and toDate(toTimezone(timestamp, {{String(timezone, 'Etc/UTC', description="Site timezone", required=True)}})) <= today() {% end %}
                 {% end %}
                 {% if defined(member_status) %} and member_status IN {{ Array(member_status, "'undefined', 'free', 'paid'", description="Member status to filter on", required=False) }} {% end %}
-                {% if defined(device) %} and device = {{ String(device, description="Device to filter on", required=False) }} {% end %}
-                {% if defined(browser) %} and browser = {{ String(browser, description="Browser to filter on", required=False) }} {% end %}
-                {% if defined(os) %} and os = {{ String(os, description="Operating system to filter on", required=False) }} {% end %}
                 {% if defined(source) %} and source = {{ String(source, description="Source to filter on", required=False) }} {% end %}
                 {% if defined(location) %} and location = {{ String(location, description="Location to filter on", required=False) }} {% end %}
                 {% if defined(pathname) %} and pathname = {{ String(pathname, description="Pathname to filter on", required=False) }} {% end %}
diff --git a/ghost/core/core/server/data/tinybird/endpoints/api_top_locations.pipe b/ghost/core/core/server/data/tinybird/endpoints/api_top_locations.pipe
index 6d9c2a3005e..02f929da4ae 100644
--- a/ghost/core/core/server/data/tinybird/endpoints/api_top_locations.pipe
+++ b/ghost/core/core/server/data/tinybird/endpoints/api_top_locations.pipe
@@ -39,9 +39,6 @@ SQL >
                     )
                 )
             {% end %}
-            {% if defined(device) %} and device = {{ String(device, description="Device to filter on", required=False) }} {% end %}
-            {% if defined(browser) %} and browser = {{ String(browser, description="Browser to filter on", required=False) }} {% end %}
-            {% if defined(os) %} and os = {{ String(os, description="Operating system to filter on", required=False) }} {% end %}
             {% if defined(source) %} and source = {{ String(source, description="Source to filter on", required=False) }} {% end %}
             {% if defined(location) %} and location = {{ String(location, description="Location to filter on", required=False) }} {% end %}
             {% if defined(pathname) %} and pathname = {{ String(pathname, description="Pathname to filter on", required=False) }} {% end %}
diff --git a/ghost/core/core/server/data/tinybird/endpoints/api_top_pages.pipe b/ghost/core/core/server/data/tinybird/endpoints/api_top_pages.pipe
index 1106a9d0e5d..b6035fbcd22 100644
--- a/ghost/core/core/server/data/tinybird/endpoints/api_top_pages.pipe
+++ b/ghost/core/core/server/data/tinybird/endpoints/api_top_pages.pipe
@@ -40,11 +40,6 @@ SQL >
                 )
             )
         {% end %}
-        {% if defined(device) %} and device = {{ String(device, description="Device to filter on", required=False) }} {% end %}
-        {% if defined(browser) %} and browser = {{ String(browser, description="Browser to filter on", required=False) }} {% end %}
-        {% if defined(os) %} and os = {{ String(os, description="Operating system to filter on", required=False) }} {% end %}
-        -- we do filtering on source in the filtered_sessions pipe
-        # --{% if defined(source) %} and source = {{ String(source, description="Source to filter on", required=False) }} {% end %}
         {% if defined(location) %} and location = {{ String(location, description="Location to filter on", required=False) }} {% end %}
         {% if defined(pathname) %} and pathname = {{ String(pathname, description="Pathname to filter on", required=False) }} {% end %}
         {% if defined(post_uuid) %} and post_uuid = {{ String(post_uuid, description="Post UUID to filter on", required=False) }} {% end %}
diff --git a/ghost/core/core/server/data/tinybird/pipes/filtered_sessions.pipe b/ghost/core/core/server/data/tinybird/pipes/filtered_sessions.pipe
index 43ce8a20259..59eb72aab91 100644
--- a/ghost/core/core/server/data/tinybird/pipes/filtered_sessions.pipe
+++ b/ghost/core/core/server/data/tinybird/pipes/filtered_sessions.pipe
@@ -20,9 +20,6 @@ SQL >
                 )
             )
         {% end %}
-        {% if defined(device) %} and device = {{ String(device, description="Device to filter on", required=False) }} {% end %}
-        {% if defined(browser) %} and browser = {{ String(browser, description="Browser to filter on", required=False) }} {% end %}
-        {% if defined(os) %} and os = {{ String(os, description="Operating system to filter on", required=False) }} {% end %}
         {% if defined(source) %} and source = {{ String(source, description="Source to filter on", required=False) }} {% end %}
         {% if defined(location) %} and location = {{ String(location, description="Location to filter on", required=False) }} {% end %}
         {% if defined(pathname) %} and pathname = {{ String(pathname, description="Pathname to filter on", required=False) }} {% end %}
diff --git a/ghost/core/core/server/data/tinybird/tests/api_kpis.yaml b/ghost/core/core/server/data/tinybird/tests/api_kpis.yaml
index 0f517210dde..4b85390d954 100644
--- a/ghost/core/core/server/data/tinybird/tests/api_kpis.yaml
+++ b/ghost/core/core/server/data/tinybird/tests/api_kpis.yaml
@@ -11,30 +11,6 @@
     {"date":"2100-01-06","visits":2,"pageviews":2,"bounce_rate":1,"avg_session_sec":0}
     {"date":"2100-01-07","visits":2,"pageviews":2,"bounce_rate":1,"avg_session_sec":0}
 
-- name: Filtered by browser - Chrome
-  description: Filtered by browser - Chrome
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&browser=chrome
-  expected_result: |
-    {"date":"2100-01-01","visits":1,"pageviews":2,"bounce_rate":0,"avg_session_sec":1111}
-    {"date":"2100-01-02","visits":0,"pageviews":0,"bounce_rate":0,"avg_session_sec":0}
-    {"date":"2100-01-03","visits":1,"pageviews":3,"bounce_rate":0,"avg_session_sec":1115}
-    {"date":"2100-01-04","visits":3,"pageviews":7,"bounce_rate":0.33,"avg_session_sec":572}
-    {"date":"2100-01-05","visits":1,"pageviews":3,"bounce_rate":0,"avg_session_sec":493}
-    {"date":"2100-01-06","visits":1,"pageviews":1,"bounce_rate":1,"avg_session_sec":0}
-    {"date":"2100-01-07","visits":0,"pageviews":0,"bounce_rate":0,"avg_session_sec":0}
-
-- name: Filtered by device - desktop
-  description: Filtered by device - desktop
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&device=desktop
-  expected_result: |
-    {"date":"2100-01-01","visits":2,"pageviews":4,"bounce_rate":0,"avg_session_sec":870.5}
-    {"date":"2100-01-02","visits":1,"pageviews":3,"bounce_rate":0,"avg_session_sec":1027}
-    {"date":"2100-01-03","visits":3,"pageviews":7,"bounce_rate":0,"avg_session_sec":3333}
-    {"date":"2100-01-04","visits":3,"pageviews":7,"bounce_rate":0.33,"avg_session_sec":572}
-    {"date":"2100-01-05","visits":2,"pageviews":5,"bounce_rate":0,"avg_session_sec":308}
-    {"date":"2100-01-06","visits":2,"pageviews":2,"bounce_rate":1,"avg_session_sec":0}
-    {"date":"2100-01-07","visits":2,"pageviews":2,"bounce_rate":1,"avg_session_sec":0}
-
 - name: Filtered by location - UK
   description: Filtered by location - UK
   parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&location=GB
@@ -47,18 +23,6 @@
     {"date":"2100-01-06","visits":1,"pageviews":1,"bounce_rate":1,"avg_session_sec":0}
     {"date":"2100-01-07","visits":0,"pageviews":0,"bounce_rate":0,"avg_session_sec":0}
 
-- name: Filtered by OS - Windows
-  description: Filtered by OS - Windows
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&os=windows
-  expected_result: |
-    {"date":"2100-01-01","visits":2,"pageviews":4,"bounce_rate":0,"avg_session_sec":870.5}
-    {"date":"2100-01-02","visits":1,"pageviews":3,"bounce_rate":0,"avg_session_sec":1027}
-    {"date":"2100-01-03","visits":3,"pageviews":7,"bounce_rate":0,"avg_session_sec":3333}
-    {"date":"2100-01-04","visits":3,"pageviews":7,"bounce_rate":0.33,"avg_session_sec":572}
-    {"date":"2100-01-05","visits":2,"pageviews":5,"bounce_rate":0,"avg_session_sec":308}
-    {"date":"2100-01-06","visits":1,"pageviews":1,"bounce_rate":1,"avg_session_sec":0}
-    {"date":"2100-01-07","visits":2,"pageviews":2,"bounce_rate":1,"avg_session_sec":0}
-
 - name: Filtered by pathname - /about/
   description: Filtered by pathname - /about/
   parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&pathname=%2Fabout%2F
diff --git a/ghost/core/core/server/data/tinybird/tests/api_top_locations.yaml b/ghost/core/core/server/data/tinybird/tests/api_top_locations.yaml
index 65985ffbbc1..4c149a1847d 100644
--- a/ghost/core/core/server/data/tinybird/tests/api_top_locations.yaml
+++ b/ghost/core/core/server/data/tinybird/tests/api_top_locations.yaml
@@ -9,40 +9,12 @@
     {"location":"ES","visits":2}
     {"location":"DE","visits":1}
 
-- name: Filtered by browser - Chrome
-  description: Filtered by browser - Chrome
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&browser=chrome
-  expected_result: |
-    {"location":"GB","visits":5}
-    {"location":"DE","visits":1}
-    {"location":"ES","visits":1}
-
-- name: Filtered by device - desktop
-  description: Filtered by device - desktop
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&device=desktop
-  expected_result: |
-    {"location":"GB","visits":7}
-    {"location":"US","visits":3}
-    {"location":"FR","visits":2}
-    {"location":"ES","visits":2}
-    {"location":"DE","visits":1}
-
 - name: Filtered by location - UK
   description: Filtered by location - UK
   parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&location=GB
   expected_result: |
     {"location":"GB","visits":8}
 
-- name: Filtered by OS - Windows
-  description: Filtered by OS - Windows
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&os=windows
-  expected_result: |
-    {"location":"GB","visits":7}
-    {"location":"US","visits":3}
-    {"location":"ES","visits":2}
-    {"location":"FR","visits":1}
-    {"location":"DE","visits":1}
-
 - name: Filtered by pathname - /about/
   description: Filtered by pathname - /about/
   parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&pathname=%2Fabout%2F
@@ -98,8 +70,7 @@
 
 - name: Test with multiple filters combined
   description: Test with multiple filters combined
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&device=desktop&browser=firefox
+  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&source=bing.com&pathname=%2Fabout%2F
   expected_result: |
-    {"location":"US","visits":3}
-    {"location":"FR","visits":1}
+    {"location":"DE","visits":1}
     {"location":"GB","visits":1}
diff --git a/ghost/core/core/server/data/tinybird/tests/api_top_pages.yaml b/ghost/core/core/server/data/tinybird/tests/api_top_pages.yaml
index 2728b194090..2ecce71d7e0 100644
--- a/ghost/core/core/server/data/tinybird/tests/api_top_pages.yaml
+++ b/ghost/core/core/server/data/tinybird/tests/api_top_pages.yaml
@@ -8,23 +8,6 @@
     {"post_uuid":"","pathname":"\/","visits":7}
     {"post_uuid":"06b1b0c9-fb53-4a15-a060-3db3fde7b1dd","pathname":"\/blog\/hello-world\/","visits":1}
 
-- name: Filtered by browser - Chrome
-  description: Filtered by browser - Chrome
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&browser=chrome
-  expected_result: |
-    {"post_uuid":"6b8635fb-292f-4422-9fe4-d76cfab2ba31","pathname":"\/blog\/hello-world\/","visits":6}
-    {"post_uuid":"06b1b0c9-fb53-4a15-a060-3db3fde7b1fc","pathname":"\/about\/","visits":3}
-    {"post_uuid":"","pathname":"\/","visits":3}
-
-- name: Filtered by device - desktop
-  description: Filtered by device - desktop
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&device=desktop
-  expected_result: |
-    {"post_uuid":"06b1b0c9-fb53-4a15-a060-3db3fde7b1fc","pathname":"\/about\/","visits":8}
-    {"post_uuid":"6b8635fb-292f-4422-9fe4-d76cfab2ba31","pathname":"\/blog\/hello-world\/","visits":8}
-    {"post_uuid":"","pathname":"\/","visits":7}
-    {"post_uuid":"06b1b0c9-fb53-4a15-a060-3db3fde7b1dd","pathname":"\/blog\/hello-world\/","visits":1}
-
 - name: Filtered by location - UK
   description: Filtered by location - UK
   parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&location=GB
@@ -33,15 +16,6 @@
     {"post_uuid":"06b1b0c9-fb53-4a15-a060-3db3fde7b1fc","pathname":"\/about\/","visits":4}
     {"post_uuid":"","pathname":"\/","visits":4}
 
-- name: Filtered by OS - Windows
-  description: Filtered by OS - Windows
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&os=windows
-  expected_result: |
-    {"post_uuid":"6b8635fb-292f-4422-9fe4-d76cfab2ba31","pathname":"\/blog\/hello-world\/","visits":8}
-    {"post_uuid":"06b1b0c9-fb53-4a15-a060-3db3fde7b1fc","pathname":"\/about\/","visits":7}
-    {"post_uuid":"","pathname":"\/","visits":7}
-    {"post_uuid":"06b1b0c9-fb53-4a15-a060-3db3fde7b1dd","pathname":"\/blog\/hello-world\/","visits":1}
-
 - name: Filtered by pathname - /about/
   description: Filtered by pathname - /about/
   parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&pathname=%2Fabout%2F
@@ -90,12 +64,9 @@
 
 - name: Test with multiple filters combined
   description: Test with multiple filters combined
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&device=desktop&browser=firefox
+  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&source=bing.com&pathname=%2Fabout%2F
   expected_result: |
-    {"post_uuid":"","pathname":"\/","visits":3}
     {"post_uuid":"06b1b0c9-fb53-4a15-a060-3db3fde7b1fc","pathname":"\/about\/","visits":2}
-    {"post_uuid":"6b8635fb-292f-4422-9fe4-d76cfab2ba31","pathname":"\/blog\/hello-world\/","visits":1}
-    {"post_uuid":"06b1b0c9-fb53-4a15-a060-3db3fde7b1dd","pathname":"\/blog\/hello-world\/","visits":1}
 
 - name: Test with post_type - post
   description: Test with post_type - post
diff --git a/ghost/core/core/server/data/tinybird/tests/api_top_sources.yaml b/ghost/core/core/server/data/tinybird/tests/api_top_sources.yaml
index 927f0021089..7e6c8914b96 100644
--- a/ghost/core/core/server/data/tinybird/tests/api_top_sources.yaml
+++ b/ghost/core/core/server/data/tinybird/tests/api_top_sources.yaml
@@ -13,28 +13,6 @@
     {"source":"petty-queen.com","visits":1}
     {"source":"my-ghost-site.com","visits":1}
 
-- name: Filtered by browser - Chrome
-  description: Filtered by browser - Chrome
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&browser=chrome
-  expected_result: |
-    {"source":"","visits":4}
-    {"source":"bing.com","visits":1}
-    {"source":"search.yahoo.com","visits":1}
-    {"source":"baidu.com","visits":1}
-
-- name: Filtered by device - desktop
-  description: Filtered by device - desktop
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&device=desktop
-  expected_result: |
-    {"source":"","visits":6}
-    {"source":"bing.com","visits":2}
-    {"source":"search.yahoo.com","visits":2}
-    {"source":"google.com","visits":1}
-    {"source":"baidu.com","visits":1}
-    {"source":"wilted-tick.com","visits":1}
-    {"source":"duckduckgo.com","visits":1}
-    {"source":"my-ghost-site.com","visits":1}
-
 - name: Filtered by location - UK
   description: Filtered by location - UK
   parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&location=GB
@@ -46,19 +24,6 @@
     {"source":"baidu.com","visits":1}
     {"source":"petty-queen.com","visits":1}
 
-- name: Filtered by OS - Windows
-  description: Filtered by OS - Windows
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&os=windows
-  expected_result: |
-    {"source":"","visits":5}
-    {"source":"bing.com","visits":2}
-    {"source":"search.yahoo.com","visits":2}
-    {"source":"google.com","visits":1}
-    {"source":"baidu.com","visits":1}
-    {"source":"wilted-tick.com","visits":1}
-    {"source":"duckduckgo.com","visits":1}
-    {"source":"my-ghost-site.com","visits":1}
-
 - name: Filtered by pathname - /about/
   description: Filtered by pathname - /about/
   parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&pathname=%2Fabout%2F
@@ -118,13 +83,9 @@
 
 - name: Test with multiple filters combined
   description: Test with multiple filters combined
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&device=desktop&browser=firefox
+  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&source=bing.com&pathname=%2Fabout%2F
   expected_result: |
-    {"source":"google.com","visits":1}
-    {"source":"search.yahoo.com","visits":1}
-    {"source":"wilted-tick.com","visits":1}
-    {"source":"duckduckgo.com","visits":1}
-    {"source":"my-ghost-site.com","visits":1}
+    {"source":"bing.com","visits":2}
 
 - name: Filtered by utm_source - google
   description: Filtered by utm_source - google
diff --git a/ghost/core/core/server/data/tinybird/tests/api_top_utm_campaigns.yaml b/ghost/core/core/server/data/tinybird/tests/api_top_utm_campaigns.yaml
index c987c4f27f0..b9d67eb5c16 100644
--- a/ghost/core/core/server/data/tinybird/tests/api_top_utm_campaigns.yaml
+++ b/ghost/core/core/server/data/tinybird/tests/api_top_utm_campaigns.yaml
@@ -10,25 +10,6 @@
     {"utm_campaign":"retention_q4","visits":1}
     {"utm_campaign":"newsletter_weekly","visits":1}
 
-- name: Filtered by browser - Chrome
-  description: Filtered by browser - Chrome
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&browser=chrome
-  expected_result: |
-    {"utm_campaign":"brand_awareness","visits":2}
-    {"utm_campaign":"summer_sale_2024","visits":1}
-    {"utm_campaign":"retention_q4","visits":1}
-
-- name: Filtered by device - desktop
-  description: Filtered by device - desktop
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&device=desktop
-  expected_result: |
-    {"utm_campaign":"brand_awareness","visits":2}
-    {"utm_campaign":"holiday_promo","visits":2}
-    {"utm_campaign":"product_launch","visits":2}
-    {"utm_campaign":"summer_sale_2024","visits":1}
-    {"utm_campaign":"retention_q4","visits":1}
-    {"utm_campaign":"newsletter_weekly","visits":1}
-
 - name: Filtered by location - UK
   description: Filtered by location - UK
   parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&location=GB
@@ -38,17 +19,6 @@
     {"utm_campaign":"product_launch","visits":1}
     {"utm_campaign":"newsletter_weekly","visits":1}
 
-- name: Filtered by OS - Windows
-  description: Filtered by OS - Windows
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&os=windows
-  expected_result: |
-    {"utm_campaign":"brand_awareness","visits":2}
-    {"utm_campaign":"holiday_promo","visits":2}
-    {"utm_campaign":"product_launch","visits":2}
-    {"utm_campaign":"summer_sale_2024","visits":1}
-    {"utm_campaign":"retention_q4","visits":1}
-    {"utm_campaign":"newsletter_weekly","visits":1}
-
 - name: Filtered by pathname - /about/
   description: Filtered by pathname - /about/
   parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&pathname=%2Fabout%2F
@@ -103,7 +73,7 @@
 
 - name: Test with multiple filters combined
   description: Test with multiple filters combined
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&device=desktop&browser=firefox
+  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&source=bing.com&pathname=%2Fabout%2F
   expected_result: |
-    {"utm_campaign":"holiday_promo","visits":2}
-    {"utm_campaign":"product_launch","visits":2}
+    {"utm_campaign":"retention_q4","visits":1}
+    {"utm_campaign":"newsletter_weekly","visits":1}
diff --git a/ghost/core/core/server/data/tinybird/tests/api_top_utm_contents.yaml b/ghost/core/core/server/data/tinybird/tests/api_top_utm_contents.yaml
index ff57c8e80b7..a8b7a95e48b 100644
--- a/ghost/core/core/server/data/tinybird/tests/api_top_utm_contents.yaml
+++ b/ghost/core/core/server/data/tinybird/tests/api_top_utm_contents.yaml
@@ -12,28 +12,6 @@
     {"utm_content":"search_ad","visits":1}
     {"utm_content":"header_link","visits":1}
 
-- name: Filtered by browser - Chrome
-  description: Filtered by browser - Chrome
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&browser=chrome
-  expected_result: |
-    {"utm_content":"post_123","visits":1}
-    {"utm_content":"video_ad","visits":1}
-    {"utm_content":"story_789","visits":1}
-    {"utm_content":"banner_ad","visits":1}
-
-- name: Filtered by device - desktop
-  description: Filtered by device - desktop
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&device=desktop
-  expected_result: |
-    {"utm_content":"post_123","visits":1}
-    {"utm_content":"video_ad","visits":1}
-    {"utm_content":"story_789","visits":1}
-    {"utm_content":"sponsored_post","visits":1}
-    {"utm_content":"tweet_456","visits":1}
-    {"utm_content":"banner_ad","visits":1}
-    {"utm_content":"search_ad","visits":1}
-    {"utm_content":"header_link","visits":1}
-
 - name: Filtered by location - UK
   description: Filtered by location - UK
   parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&location=GB
@@ -43,19 +21,6 @@
     {"utm_content":"banner_ad","visits":1}
     {"utm_content":"header_link","visits":1}
 
-- name: Filtered by OS - Windows
-  description: Filtered by OS - Windows
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&os=windows
-  expected_result: |
-    {"utm_content":"post_123","visits":1}
-    {"utm_content":"video_ad","visits":1}
-    {"utm_content":"story_789","visits":1}
-    {"utm_content":"sponsored_post","visits":1}
-    {"utm_content":"tweet_456","visits":1}
-    {"utm_content":"banner_ad","visits":1}
-    {"utm_content":"search_ad","visits":1}
-    {"utm_content":"header_link","visits":1}
-
 - name: Filtered by pathname - /about/
   description: Filtered by pathname - /about/
   parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&pathname=%2Fabout%2F
@@ -110,8 +75,7 @@
 
 - name: Test with multiple filters combined
   description: Test with multiple filters combined
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&device=desktop&browser=firefox
+  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&source=bing.com&pathname=%2Fabout%2F
   expected_result: |
-    {"utm_content":"sponsored_post","visits":1}
-    {"utm_content":"tweet_456","visits":1}
-    {"utm_content":"search_ad","visits":1}
+    {"utm_content":"story_789","visits":1}
+    {"utm_content":"header_link","visits":1}
diff --git a/ghost/core/core/server/data/tinybird/tests/api_top_utm_mediums.yaml b/ghost/core/core/server/data/tinybird/tests/api_top_utm_mediums.yaml
index d89f40a2e8f..8120a21e5f2 100644
--- a/ghost/core/core/server/data/tinybird/tests/api_top_utm_mediums.yaml
+++ b/ghost/core/core/server/data/tinybird/tests/api_top_utm_mediums.yaml
@@ -10,26 +10,6 @@
     {"utm_medium":"display","visits":1}
     {"utm_medium":"email","visits":1}
 
-- name: Filtered by browser - Chrome
-  description: Filtered by browser - Chrome
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&browser=chrome
-  expected_result: |
-    {"utm_medium":"social","visits":2}
-    {"utm_medium":"organic","visits":1}
-    {"utm_medium":"referral","visits":1}
-    {"utm_medium":"display","visits":1}
-
-- name: Filtered by device - desktop
-  description: Filtered by device - desktop
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&device=desktop
-  expected_result: |
-    {"utm_medium":"social","visits":5}
-    {"utm_medium":"cpc","visits":1}
-    {"utm_medium":"organic","visits":1}
-    {"utm_medium":"referral","visits":1}
-    {"utm_medium":"display","visits":1}
-    {"utm_medium":"email","visits":1}
-
 - name: Filtered by location - UK
   description: Filtered by location - UK
   parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&location=GB
@@ -41,17 +21,6 @@
     {"utm_medium":"display","visits":1}
     {"utm_medium":"email","visits":1}
 
-- name: Filtered by OS - Windows
-  description: Filtered by OS - Windows
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&os=windows
-  expected_result: |
-    {"utm_medium":"social","visits":5}
-    {"utm_medium":"cpc","visits":1}
-    {"utm_medium":"organic","visits":1}
-    {"utm_medium":"referral","visits":1}
-    {"utm_medium":"display","visits":1}
-    {"utm_medium":"email","visits":1}
-
 - name: Filtered by pathname - /about/
   description: Filtered by pathname - /about/
   parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&pathname=%2Fabout%2F
@@ -104,7 +73,7 @@
 
 - name: Test with multiple filters combined
   description: Test with multiple filters combined
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&device=desktop&browser=firefox
+  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&source=bing.com&pathname=%2Fabout%2F
   expected_result: |
-    {"utm_medium":"social","visits":3}
-    {"utm_medium":"cpc","visits":1}
+    {"utm_medium":"social","visits":1}
+    {"utm_medium":"email","visits":1}
diff --git a/ghost/core/core/server/data/tinybird/tests/api_top_utm_sources.yaml b/ghost/core/core/server/data/tinybird/tests/api_top_utm_sources.yaml
index dd777826d8a..31bd583cce0 100644
--- a/ghost/core/core/server/data/tinybird/tests/api_top_utm_sources.yaml
+++ b/ghost/core/core/server/data/tinybird/tests/api_top_utm_sources.yaml
@@ -13,30 +13,6 @@
     {"utm_source":"partner_site","visits":1}
     {"utm_source":"newsletter","visits":1}
 
-- name: Filtered by browser - Chrome
-  description: Filtered by browser - Chrome
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&browser=chrome
-  expected_result: |
-    {"utm_source":"google","visits":1}
-    {"utm_source":"facebook","visits":1}
-    {"utm_source":"bing","visits":1}
-    {"utm_source":"instagram","visits":1}
-    {"utm_source":"partner_site","visits":1}
-
-- name: Filtered by device - desktop
-  description: Filtered by device - desktop
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&device=desktop
-  expected_result: |
-    {"utm_source":"google","visits":2}
-    {"utm_source":"linkedin","visits":1}
-    {"utm_source":"twitter","visits":1}
-    {"utm_source":"facebook","visits":1}
-    {"utm_source":"bing","visits":1}
-    {"utm_source":"reddit","visits":1}
-    {"utm_source":"instagram","visits":1}
-    {"utm_source":"partner_site","visits":1}
-    {"utm_source":"newsletter","visits":1}
-
 - name: Filtered by location - UK
   description: Filtered by location - UK
   parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&location=GB
@@ -47,20 +23,6 @@
     {"utm_source":"partner_site","visits":1}
     {"utm_source":"newsletter","visits":1}
 
-- name: Filtered by OS - Windows
-  description: Filtered by OS - Windows
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&os=windows
-  expected_result: |
-    {"utm_source":"google","visits":2}
-    {"utm_source":"linkedin","visits":1}
-    {"utm_source":"twitter","visits":1}
-    {"utm_source":"facebook","visits":1}
-    {"utm_source":"bing","visits":1}
-    {"utm_source":"reddit","visits":1}
-    {"utm_source":"instagram","visits":1}
-    {"utm_source":"partner_site","visits":1}
-    {"utm_source":"newsletter","visits":1}
-
 - name: Filtered by pathname - /about/
   description: Filtered by pathname - /about/
   parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&pathname=%2Fabout%2F
@@ -120,9 +82,7 @@
 
 - name: Test with multiple filters combined
   description: Test with multiple filters combined
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&device=desktop&browser=firefox
+  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&source=bing.com&pathname=%2Fabout%2F
   expected_result: |
-    {"utm_source":"linkedin","visits":1}
-    {"utm_source":"twitter","visits":1}
-    {"utm_source":"google","visits":1}
-    {"utm_source":"reddit","visits":1}
+    {"utm_source":"instagram","visits":1}
+    {"utm_source":"newsletter","visits":1}
diff --git a/ghost/core/core/server/data/tinybird/tests/api_top_utm_terms.yaml b/ghost/core/core/server/data/tinybird/tests/api_top_utm_terms.yaml
index 4db233849d8..7d952d4a2f2 100644
--- a/ghost/core/core/server/data/tinybird/tests/api_top_utm_terms.yaml
+++ b/ghost/core/core/server/data/tinybird/tests/api_top_utm_terms.yaml
@@ -11,26 +11,6 @@
     {"utm_term":"new_feature","visits":1}
     {"utm_term":"announcement","visits":1}
 
-- name: Filtered by browser - Chrome
-  description: Filtered by browser - Chrome
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&browser=chrome
-  expected_result: |
-    {"utm_term":"discount","visits":1}
-    {"utm_term":"ghost_blog","visits":1}
-    {"utm_term":"loyal_customers","visits":1}
-
-- name: Filtered by device - desktop
-  description: Filtered by device - desktop
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&device=desktop
-  expected_result: |
-    {"utm_term":"discount","visits":1}
-    {"utm_term":"ghost_blog","visits":1}
-    {"utm_term":"subscribers","visits":1}
-    {"utm_term":"loyal_customers","visits":1}
-    {"utm_term":"black_friday","visits":1}
-    {"utm_term":"new_feature","visits":1}
-    {"utm_term":"announcement","visits":1}
-
 - name: Filtered by location - UK
   description: Filtered by location - UK
   parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&location=GB
@@ -40,18 +20,6 @@
     {"utm_term":"subscribers","visits":1}
     {"utm_term":"new_feature","visits":1}
 
-- name: Filtered by OS - Windows
-  description: Filtered by OS - Windows
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&os=windows
-  expected_result: |
-    {"utm_term":"discount","visits":1}
-    {"utm_term":"ghost_blog","visits":1}
-    {"utm_term":"subscribers","visits":1}
-    {"utm_term":"loyal_customers","visits":1}
-    {"utm_term":"black_friday","visits":1}
-    {"utm_term":"new_feature","visits":1}
-    {"utm_term":"announcement","visits":1}
-
 - name: Filtered by pathname - /about/
   description: Filtered by pathname - /about/
   parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&pathname=%2Fabout%2F
@@ -108,8 +76,7 @@
 
 - name: Test with multiple filters combined
   description: Test with multiple filters combined
-  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&device=desktop&browser=firefox
+  parameters: site_uuid=mock_site_uuid&date_from=2100-01-01&date_to=2100-01-07&timezone=Etc/UTC&source=bing.com&pathname=%2Fabout%2F
   expected_result: |
-    {"utm_term":"black_friday","visits":1}
-    {"utm_term":"new_feature","visits":1}
-    {"utm_term":"announcement","visits":1}
+    {"utm_term":"subscribers","visits":1}
+    {"utm_term":"loyal_customers","visits":1}
diff --git a/ghost/core/core/server/services/tinybird/TinybirdService.js b/ghost/core/core/server/services/tinybird/TinybirdService.js
index 9d6e903ac61..a076ec8f0dc 100644
--- a/ghost/core/core/server/services/tinybird/TinybirdService.js
+++ b/ghost/core/core/server/services/tinybird/TinybirdService.js
@@ -48,10 +48,7 @@ const TINYBIRD_PIPES = [
     'api_kpis',
     'api_active_visitors',
     'api_post_visitor_counts',
-    'api_top_browsers',
-    'api_top_devices',
     'api_top_locations',
-    'api_top_os',
     'api_top_pages',
     'api_top_sources',
     'api_top_utm_sources',
@@ -63,6 +60,10 @@ const TINYBIRD_PIPES = [
 
 /**
  * Service for managing Tinybird JWT tokens and authentication
+ *
+ * To run Tinybird tests locally:
+ * npm install -g @tinybird/cli
+ * npm run docker:dev:analytics
  */
 class TinybirdService {
     /**
@@ -94,7 +95,7 @@ class TinybirdService {
             // Generate a new JWT token if it doesn't exist or is expired
             if (!this._serverToken || this._isJWTExpired(this._serverToken)) {
                 const tokenData = this._generateToken({name, expiresInMinutes});
-                this._serverToken = tokenData.token;
+                this._serverToken = tokenData;
                 this._serverTokenExp = tokenData.exp;
             }
             return {
@@ -126,7 +127,7 @@ class TinybirdService {
      */
     _generateToken({name = `tinybird-jwt-${this.siteUuid}`, expiresInMinutes = 60} = {}) {
         const expiresAt = Math.floor(Date.now() / 1000) + expiresInMinutes * 60;
-        
+
         /** @type {TinybirdJWTPayload} */
         const payload = {
             workspace_id: this.tinybirdConfig.workspaceId,
@@ -143,8 +144,8 @@ class TinybirdService {
             })
         };
 
-        const token = jwt.sign(payload, this.tinybirdConfig.adminToken, {noTimestamp: true});
-        
+        const token = jwt.sign(payload, this.tinybirdConfig.adminToken);
+
         return {
             token,
             exp: expiresAt
@@ -160,7 +161,7 @@ class TinybirdService {
      */
     _isJWTExpired(token, bufferSeconds = 300) {
         try {
-            const decoded = jwt.verify(token, this.tinybirdConfig.adminToken);
+            const decoded = jwt.decode(token);
             if (typeof decoded !== 'object' || !decoded.exp) {
                 return true;
             }
QODO_BENCH_DIFF_END
