# Kịch bản storytelling cho LaplapTech Analytics Report

## 1. Bối cảnh và mục tiêu

LaplapTech là một trang tổng hợp và so sánh các dòng thiết bị điện tử của một YouTuber công nghệ. Danh mục hiện có dưới 200 sản phẩm nên dataset chưa đủ rộng để đại diện cho toàn bộ thị trường hoặc hỗ trợ các quyết định về sản xuất và chuỗi cung ứng.

Giá trị chính của dữ liệu nằm ở lượng event tracking từ thao tác của người dùng. Project tập trung trả lời:

1. Người dùng đang xem và tìm kiếm sản phẩm nào?
2. Sản phẩm nào được đưa vào hành vi so sánh?
3. Người dùng quan tâm tiêu chí nào khi so sánh?
4. Nhóm sản phẩm hoặc góc nội dung nào có tiềm năng?
	1. Trang có đang cung cấp đủ thông tin cho các sản phẩm được quan tâm không?

Đối tượng sử dụng insight là reviewer công nghệ, tác giả của trang và các content/marketing agency như Schannel.

## 2. Mạch kể chuyện chính

```text
Dữ liệu có đáng tin cậy không?
    -> Người dùng đang hoạt động như thế nào?
    -> Sản phẩm nào thu hút lượt xem?
    -> Sản phẩm nào được cân nhắc sâu qua comparison?
    -> Người dùng đang đánh giá trade-off và thông số nào?
    -> Nên sản xuất nội dung nào?
    -> Nên bổ sung dữ liệu cho sản phẩm nào?
```

Không nên trình bày report như một tập hợp các biểu đồ rời rạc. Mỗi trang cần trả lời một business question và tạo câu dẫn sang trang tiếp theo.

## 3. Trang 1 - Data Reliability

### Câu hỏi

**Can we trust the behavioral data?**

### Nội dung phân tích

- Phạm vi thời gian của dữ liệu.
- Tổng số event và số ngày có dữ liệu.
- Tỷ lệ null của `session_id`, `user_id`, `event_name` và timestamp.
- Số event trùng lặp.
- Số `session_id` được gắn với nhiều `user_id`.
- Độ lệch giữa local timestamp và server timestamp.
- Ngày có volume tăng, giảm hoặc đứt đoạn bất thường.

### Lời dẫn

> Trước khi phân tích hành vi, cần xác định event tracking có đủ tin cậy hay không. Local timestamp trong dữ liệu có nhiều trường hợp lệch đáng kể so với thời điểm server nhận event. Vì vậy, report sử dụng `event_received_on_server_timestamp` làm nguồn thời gian chính. Local timestamp chỉ được giữ để kiểm tra chất lượng tracking.

> `session_id` được sử dụng để nhóm hành vi người dùng và tạm thời đại diện cho một comparison session. Trước khi sử dụng, cần kiểm tra tỷ lệ null và trường hợp một session được gắn với nhiều user.

### Kết luận chuyển tiếp

> Sau khi thống nhất timestamp và mức độ tin cậy của session, có thể quan sát mức độ hoạt động chung của website.

Nếu chưa hoàn thành ad hoc, phần này phải được đánh dấu là `Work in progress`, không khẳng định dữ liệu đã hoàn toàn sạch.

## 4. Trang 2 - Website Activity Overview

### Câu hỏi

**How are users interacting with the website?**

### KPI đề xuất

- Total events.
- Total sessions.
- Active users.
- Product detail views.
- Comparison sessions.
- Tỷ lệ session có hành vi comparison.
- Volume event theo ngày.

### Phân nhóm hành vi

```text
Traffic
- pageview

Discovery
- search_for_device
- load_more_device_home

Comparison
- add_to_comparison
- select_device_for_comparison
- comparison_chart_sort_selection

Authentication
- user_login
```

### Lời dẫn

> Các event được phân thành traffic, discovery, comparison và authentication. Traffic cho biết người dùng đã đến và xem nội dung; discovery phản ánh nhu cầu tìm kiếm; comparison thể hiện mức độ cân nhắc sâu hơn đối với sản phẩm.

> Thay vì chỉ nhìn tổng số event, report tập trung vào sự dịch chuyển từ xem nội dung sang khám phá và so sánh.

### Mẫu điền insight

> Trong giai đoạn `[từ ngày]` đến `[đến ngày]`, website ghi nhận `[X]` sessions và `[Y]` lượt xem trang sản phẩm. `[Z%]` session có ít nhất một hành vi liên quan đến comparison.

### Câu dẫn

> Traffic cho biết nội dung nào thu hút sự chú ý. Tuy nhiên, sản phẩm được xem nhiều chưa chắc là sản phẩm người dùng thực sự cân nhắc, vì vậy cần tách hai cấp độ quan tâm.

## 5. Trang 3 - Product Interest

### Câu hỏi

**Which products attract the most attention?**

### Định nghĩa

```text
General interest
= người dùng truy cập trang chi tiết sản phẩm

Specification interest
= người dùng đưa sản phẩm vào hành vi so sánh
```

### Nội dung phân tích

- Top sản phẩm được xem.
- Product views theo ngày.
- Views theo brand.
- Views theo `usage_segment`.
- Views theo CPU, GPU và năm giới thiệu.
- Xu hướng quan tâm tăng hoặc giảm theo thời gian.

### Lời dẫn

> Lượt xem trang chi tiết là tín hiệu đầu tiên cho thấy một sản phẩm thu hút sự chú ý. Đây có thể là kết quả của nhu cầu tìm hiểu, độ phổ biến của sản phẩm hoặc nội dung bên ngoài dẫn người dùng đến trang.

> Các sản phẩm đứng đầu về lượt xem là ứng viên phù hợp cho bài review, cập nhật thông tin hoặc nội dung giải thích chuyên sâu.

### Giới hạn kết luận

Không kết luận rằng một sản phẩm được toàn thị trường yêu thích nhất. Cách diễn đạt phù hợp là:

> Trong phạm vi người dùng và danh mục sản phẩm của LaplapTech, `[sản phẩm]` nhận được nhiều lượt xem nhất.

## 6. Trang 4 - Comparison Interest

### Câu hỏi

**Which products require deeper consideration?**

### Nội dung phân tích

- Top sản phẩm xuất hiện trong comparison sessions.
- Compared sessions theo ngày.
- Comparison interest theo brand và segment.
- So sánh thứ hạng product view và thứ hạng comparison.
- Ma trận product views và compared sessions.

### Khung diễn giải

| Nhóm | Ý nghĩa | Hướng hành động |
|---|---|---|
| View cao, comparison cao | Quan tâm mạnh và cân nhắc sâu | Review, benchmark, comparison content |
| View cao, comparison thấp | Thu hút chú ý nhưng ít cân nhắc | Overview, FAQ, hướng dẫn chọn mua |
| View thấp, comparison cao | Niche nhưng có nhu cầu đánh giá sâu | Technical deep dive |
| View thấp, comparison thấp | Mức quan tâm thấp | Chưa cần ưu tiên |

### Lời dẫn

> Lượt xem phản ánh sự chú ý chung, trong khi comparison thể hiện nhu cầu đánh giá dựa trên thông số hoặc đặt sản phẩm cạnh các lựa chọn khác.

> Một sản phẩm có nhiều lượt xem nhưng ít được so sánh có thể phù hợp với nội dung giới thiệu. Một sản phẩm có lượng xem vừa phải nhưng comparison cao có thể nằm trong một quyết định mua phức tạp và phù hợp với nội dung chuyên sâu.

### Limitation bắt buộc

> Các sản phẩm hiện được nhóm theo cùng `session_id`. Do dữ liệu chưa có định danh riêng cho từng bảng comparison, report chỉ kết luận rằng chúng xuất hiện trong cùng comparison session, không khẳng định chắc chắn chúng nằm trong cùng một bảng so sánh.

## 7. Trang 5 - Comparison Context

Đây là nhóm ad hoc chưa hoàn thành và phải được trình bày dưới dạng câu hỏi phân tích tiếp theo cho đến khi có kết quả thực tế.

### 7.1. Các phân khúc thường được so sánh

**What trade-offs are users trying to evaluate?**

Ví dụ output mong muốn:

```text
gaming laptop <-> gaming laptop
gaming laptop <-> workstation
general laptop <-> mobile device
```

### Lời dẫn

> Việc biết sản phẩm nào được quan tâm mới chỉ trả lời câu hỏi "what". Để tìm content angle, cần hiểu người dùng đang cân nhắc giữa những lựa chọn nào. Các cặp phân khúc xuất hiện trong cùng session có thể phản ánh các trade-off như hiệu năng và tính di động hoặc gaming và công việc chuyên nghiệp.

### 7.2. Tiêu chí sort comparison

Event sử dụng:

```text
comparison_chart_sort_selection
```

Các JSON key đã được xác nhận:

```text
device_ids
sort_by
sort_direction
```

### Lời dẫn

> Tiêu chí sort cho biết thông số nào được người dùng chủ động sử dụng để đánh giá sản phẩm. Nếu laptop gaming thường được sort theo GPU hoặc TDP, content nên nhấn mạnh hiệu năng. Nếu laptop mobile thường được sort theo trọng lượng hoặc pin, content nên tập trung vào tính di động.

Không được trình bày các ví dụ trên như insight thực tế trước khi ad hoc được hoàn thành.

## 8. Trang 6 - Behavioral Funnel

### Câu hỏi

**How far do users progress in the comparison journey?**

### Funnel đề xuất

```text
Pageview
-> Search hoặc load more
-> Add to comparison
-> Select device for comparison
-> Sort comparison chart
```

### Metrics

- Số session đạt từng bước.
- Conversion rate giữa hai bước liên tiếp.
- Conversion rate từ đầu đến cuối funnel.
- Drop-off rate.
- Funnel theo ngày, OS hoặc product segment nếu dữ liệu cho phép.

### Quy ước

- Một session đạt một bước chỉ được tính một lần ở bước đó.
- Nếu yêu cầu funnel đúng thứ tự, timestamp của bước sau phải lớn hơn hoặc bằng bước trước.
- Cần phân biệt funnel tuần tự với việc chỉ kiểm tra session có chứa event.

### Lời dẫn

> Funnel cho biết mức độ người dùng đi sâu từ xem nội dung đến sử dụng công cụ comparison. Drop-off cao sau search có thể phản ánh vấn đề ở kết quả tìm kiếm. Drop-off sau khi add product có thể liên quan đến trải nghiệm chọn sản phẩm tiếp theo.

## 9. Trang 7 - Data Coverage and Update Priority

### Câu hỏi

**Is the product database keeping up with user interest?**

### Các field có thể đánh giá completeness

```text
CPU
GPU
CPU TDP
GPU TDP
battery capacity
screen size
screen resolution
screen PPI
laptop weight
charger weight
thumbnail
benchmark result
review video
```

Các field nên được chia thành `critical`, `important` và `optional`, không coi tất cả field có trọng số bằng nhau.

### Công thức định hướng

```text
Update priority
= product views
+ compared sessions
+ interest growth
+ important fields missing
```

### Khung hành động

| Interest | Completeness | Hành động |
|---|---|---|
| Cao | Thấp | Cập nhật ngay |
| Cao | Cao | Duy trì và làm content |
| Thấp | Thấp | Ưu tiên thấp |
| Thấp | Cao | Theo dõi, chưa cần đầu tư thêm |

### Lời dẫn

> Một trang comparison chỉ tạo ra giá trị khi các sản phẩm được người dùng quan tâm có dữ liệu đầy đủ và cập nhật. Sản phẩm có traffic hoặc comparison cao nhưng thiếu thông số quan trọng tạo ra khoảng cách giữa nhu cầu người dùng và khả năng phục vụ của website.

> Report không chỉ đề xuất làm content gì mà còn chỉ ra sản phẩm nào cần được bổ sung dữ liệu trước.

## 11. Kết luận report

> Dữ liệu LaplapTech không đại diện cho toàn bộ thị trường thiết bị điện tử, nhưng cung cấp tín hiệu trực tiếp về nhu cầu của tệp người dùng trên nền tảng.

> Lượt xem cho biết sản phẩm nào thu hút sự chú ý. Comparison cho biết sản phẩm nào cần được cân nhắc sâu. Sort criteria cho biết người dùng quan tâm thông số nào. Data completeness cho biết website đã đáp ứng nhu cầu đó đến đâu.

Hai nhóm quyết định cuối cùng:

1. Reviewer và agency nên ưu tiên nội dung nào.
2. Website nên ưu tiên cập nhật dữ liệu sản phẩm nào.

## 12. Model dbt hiện có

### Intermediate

| Model | Grain | Vai trò |
|---|---|---|
| `int_device_traffic` | Một dòng trên một event DeviceDetail hợp lệ | Extract `device_id` và hành vi truy cập trang sản phẩm |
| `int_comparison_event` | Một dòng trên một `session_id + device_id` | Danh sách sản phẩm duy nhất xuất hiện trong comparison session |
| `int_event_behavior` | Một dòng trên một event | Chuẩn hóa event thành traffic, discovery, comparison, authentication hoặc other |
| `int_session_activity` | Một dòng trên một `session_id` | Tổng hợp hoạt động và cờ hành vi ở cấp session |
| `int_session_funnel` | Một dòng trên một DeviceDetail session | Xác định các bước funnel theo đúng thứ tự thời gian |
| `int_product_interest_daily` | Một dòng trên một `event_date + device_id` | Kết hợp lượt xem và comparison interest hằng ngày |
| `int_product_interest_trend` | Một dòng trên một `week + device_id` | So sánh interest với kỳ quan sát trước |
| `int_comparison_sort_event` | Một dòng trên một sort event | Extract `device_ids`, `sort_by` và `sort_direction` từ JSON |
| `int_comparison_sort_segment_pair` | Một dòng trên một `sort event + segment pair` | Gắn tiêu chí sort với đúng các sản phẩm trong comparison payload |
| `int_comparison_segment_pair` | Một dòng trên một `session_id + segment pair` | Tạo cặp phân khúc không phân biệt thứ tự |
| `int_product_data_completeness` | Một dòng trên một `device_id` | Đo completeness và danh sách field còn thiếu |

### Gold

| Model | Grain | Vai trò |
|---|---|---|
| `mart_device_traffic` | Một dòng trên một `event_date + device_id` | Lượt xem và viewing sessions theo sản phẩm/ngày |
| `mart_compared_devices_daily` | Một dòng trên một `event_date + device_id` | Compared sessions theo sản phẩm/ngày |
| `mart_most_compared_devices` | Một dòng trên một `device_id` | Xếp hạng comparison toàn giai đoạn |
| `mart_daily_site_kpis` | Một dòng trên một ngày | KPI traffic, user, session, discovery và comparison |
| `mart_behavior_funnel_daily` | Một dòng trên một `cohort_date + funnel_step` | Conversion và drop-off của funnel |
| `mart_product_interest` | Một dòng trên một `week + device_id` | Interest score và phân nhóm view/comparison |
| `mart_comparison_segment_pairs` | Một dòng trên một segment pair | Các phân khúc thường xuất hiện trong cùng comparison session |
| `mart_comparison_sort_criteria` | Một dòng trên segment pair, sort field và direction | Tiêu chí người dùng dùng để sort comparison |
| `mart_product_data_quality_priority` | Một dòng trên một sản phẩm active | Ưu tiên cập nhật dựa trên demand và completeness |

`mart_user_os` đang được phát triển và chưa nên coi là model hoàn chỉnh cho đến khi xác định rõ grain và metric cần phân tích.

## 13. Intermediate models đã bổ sung

Các model dưới đây đã được tạo bằng BigQuery SQL. JSON của sort event đã được xác nhận gồm `device_ids`, `sort_by` và `sort_direction`.

### 13.1. `int_event_behavior`

**Mục đích:** Chuẩn hóa event thành nhóm hành vi.

**Grain:** Một dòng trên một event.

**Input:** `silver_user_event_tracking`.

**Output chính:**

```text
event_id
event_at_timestamp
event_date
session_id
user_id
event_name
behavior_group
device_id
```

Mapping `behavior_group`:

```text
traffic
discovery
comparison
authentication
other
```

### 13.2. `int_session_activity`

**Mục đích:** Tạo nền tảng cho KPI theo session.

**Grain:** Một dòng trên một `session_id`.

**Input:** `int_event_behavior`.

**Output chính:**

```text
session_id
user_id
session_started_at
session_ended_at
session_date
event_count
product_view_count
has_discovery
has_comparison
has_login
```

### 13.3. `int_session_funnel`

**Mục đích:** Xác định mỗi session đã đạt các bước nào trong funnel.

**Grain:** Một dòng trên một `session_id`.

**Input:** `int_event_behavior`.

**Output chính:**

```text
session_id
session_date
reached_pageview
reached_discovery
reached_add_to_comparison
reached_select_for_comparison
reached_comparison_sort
first_pageview_at
first_discovery_at
first_add_to_comparison_at
first_select_for_comparison_at
first_comparison_sort_at
```

### 13.4. `int_product_interest_daily`

**Mục đích:** Kết hợp product views và comparison interest.

**Grain:** Một dòng trên một `event_date + device_id`.

**Input:** `mart_device_traffic` và `mart_compared_devices_daily`, hoặc trực tiếp từ hai intermediate model tương ứng.

**Output chính:**

```text
event_date
device_id
page_views
viewing_sessions
compared_sessions
comparison_to_view_ratio
```

### 13.5. `int_product_interest_trend`

**Mục đích:** Đo xu hướng tăng hoặc giảm của interest.

**Grain:** Một dòng trên một `period_start + device_id`.

**Input:** `int_product_interest_daily`.

**Output chính:**

```text
period_start
device_id
current_views
previous_views
view_growth_rate
current_compared_sessions
previous_compared_sessions
comparison_growth_rate
```

Nên dùng tuần thay vì ngày nếu traffic không đủ lớn.

### 13.6. `int_comparison_sort_event`

**Mục đích:** Extract tiêu chí được dùng để sort bảng comparison.

**Grain:** Một dòng trên một `comparison_chart_sort_selection` event.

**Input:** `silver_user_event_tracking`.

**Output chính:**

```text
event_id
event_at_timestamp
event_date
session_id
device_ids
sort_field
sort_direction
```

`sort_field` trong model được chuẩn hóa từ key `sort_by` của payload.

### 13.7. `int_comparison_sort_segment_pair`

**Mục đích:** Gắn tiêu chí sort với đúng các phân khúc sản phẩm xuất hiện trong payload của sort event.

**Grain:** Một dòng trên một `event_id + segment_a + segment_b`.

**Input:** `int_comparison_sort_event` và `silver_laptop_model`.

Model unnest `device_ids`, join từng ID với sản phẩm rồi tạo cặp không phân biệt thứ tự bằng `LEAST` và `GREATEST`.

### 13.8. `int_comparison_segment_pair`

**Mục đích:** Tạo các cặp phân khúc xuất hiện trong cùng comparison session.

**Grain:** Một dòng trên một `session_id + segment_a + segment_b`.

**Input:** `int_comparison_event` và `silver_laptop_model`.

**Output chính:**

```text
session_id
session_date
segment_a
segment_b
```

Phải chuẩn hóa thứ tự cặp bằng `LEAST` và `GREATEST` để tránh tách `A-B` và `B-A` thành hai cặp.

### 13.9. `int_product_data_completeness`

**Mục đích:** Đo mức độ đầy đủ thông tin của từng sản phẩm.

**Grain:** Một dòng trên một `device_id`.

**Input:** `silver_laptop_model` và `silver_laptop_benchmark_result`.

**Output chính:**

```text
device_id
missing_critical_fields
missing_important_fields
missing_optional_fields
critical_completeness_score
overall_completeness_score
missing_field_list
```

## 14. Gold marts đã bổ sung

### 14.1. `mart_daily_site_kpis`

**Grain:** Một dòng trên một `event_date`.

**Input:** `int_event_behavior` và `int_session_activity`.

**Metrics:**

```text
total_events
active_users
total_sessions
product_views
discovery_sessions
comparison_sessions
comparison_session_rate
```

**Report:** Website Activity Overview.

### 14.2. `mart_behavior_funnel_daily`

**Grain:** Một dòng trên một `event_date + funnel_step`.

**Input:** `int_session_funnel`.

**Metrics:**

```text
sessions_reached
conversion_from_previous_step
conversion_from_first_step
drop_off_sessions
drop_off_rate
```

**Report:** Behavioral Funnel.

### 14.3. `mart_product_interest`

**Grain:** Một dòng trên một `device_id` cho toàn bộ khoảng thời gian phân tích hoặc một dòng trên `period_start + device_id` nếu cần filter thời gian.

**Input:** `int_product_interest_daily` và `int_product_interest_trend`.

**Metrics:**

```text
page_views
viewing_sessions
compared_sessions
comparison_to_view_ratio
view_growth_rate
comparison_growth_rate
interest_segment
```

`interest_segment` có thể gồm:

```text
high_view_high_comparison
high_view_low_comparison
low_view_high_comparison
low_view_low_comparison
```

### 14.4. `mart_comparison_segment_pairs`

**Grain:** Một dòng trên một `segment_a + segment_b`.

**Input:** `int_comparison_segment_pair`.

**Metrics:**

```text
comparison_sessions
share_of_comparison_sessions
first_seen_at
last_seen_at
```

### 14.5. `mart_comparison_sort_criteria`

**Grain:** Một dòng trên một `sort_field`, hoặc `segment_a + segment_b + sort_field` nếu kết hợp với comparison pair.

**Input:** `int_comparison_sort_segment_pair`, được xây từ chính `device_ids` trong sort event.

**Metrics:**

```text
sort_events
sorting_sessions
share_of_sorting_sessions
```

### 14.6. `mart_product_data_quality_priority`

**Grain:** Một dòng trên một `device_id`.

**Input:** `int_product_data_completeness` và `mart_product_interest`.

**Output chính:**

```text
device_id
device_name
interest_score
trend_score
critical_completeness_score
missing_field_list
data_update_priority_score
priority_group
```

Priority group:

```text
update_now
maintain
monitor
low_priority
```

## 15. Dependency đề xuất

```text
silver_user_event_tracking
    -> int_event_behavior
        -> int_session_activity
            -> mart_daily_site_kpis
        -> int_session_funnel
            -> mart_behavior_funnel

int_device_traffic
    -> mart_device_traffic
        -> int_product_interest_daily
            -> int_product_interest_trend
                -> mart_product_interest

int_comparison_event
    -> mart_compared_devices_daily
    -> mart_most_compared_devices
    -> int_product_interest_daily
    -> int_comparison_segment_pair
        -> mart_comparison_segment_pairs

int_comparison_sort_event
    -> int_comparison_sort_segment_pair
        -> mart_comparison_sort_criteria

silver_laptop_model
silver_laptop_benchmark_result
    -> int_product_data_completeness

mart_product_interest
int_product_data_completeness
    -> mart_product_data_quality_priority
```

## 16. Thứ tự triển khai

### Phiên bản report đầu tiên

1. Project Context.
2. Data Reliability.
3. Product Traffic.
4. Product Comparison.
5. Key Findings and Limitations.
6. Next Analytical Questions.

### Model đã được triển khai

1. `int_event_behavior`.
2. `int_session_activity`.
3. `mart_daily_site_kpis`.
4. `int_session_funnel`.
5. `mart_behavior_funnel`.
6. `int_product_interest_daily`.
7. `int_product_interest_trend`.
8. `mart_product_interest`.
9. `int_comparison_sort_event` với các key đã xác nhận: `device_ids`, `sort_by`, `sort_direction`.
10. `int_comparison_sort_event`.
11. `int_comparison_segment_pair`.
12. `mart_product_data_quality_priority`.

Việc cần làm sau lần chạy BigQuery đầu tiên là kiểm tra kết quả ad hoc, xác nhận JSON key của sort event và hiệu chỉnh trọng số scoring. Không nên coi scoring version đầu tiên là business rule cố định.

Không xây `mart_content_opportunity` khi chưa có content inventory. Cần kiểm tra và hiệu chỉnh trọng số của `mart_product_data_quality_priority` sau khi chạy trên dữ liệu thật.

## 17. Nguyên tắc trình bày

- Mỗi trang phải bắt đầu bằng một business question.
- Mỗi biểu đồ cần hỗ trợ một luận điểm cụ thể.
- Phân biệt observation, interpretation và recommendation.
- Không biến giả thuyết hoặc ad hoc chưa làm thành insight.
- Luôn ghi rõ grain và định nghĩa metric.
- Nêu limitation về phạm vi dưới 200 sản phẩm và cách nhóm comparison theo session.
- Chỉ kết luận trong phạm vi người dùng và danh mục của LaplapTech, không suy rộng ra toàn thị trường.
