## 📘 第 K 大數值濾波器：完整運作流程與原理

這份架構說明非常適合用來做為專案書的 **"Design Architecture & Principles"** 章節：

### 🎯 1. 設計核心：即時 Top-K 插入排序（On-the-fly Parallel Insertion Sort）
**傳統算法挑戰：** 若要在一長串訊號流（如 63 筆資料）中尋找第 $K$ 大的數值，傳統做法是將所有資料寫入記憶體（SRAM），待全部收集完畢後執行雙重迴圈排序（如 Bubble Sort）。這在硬體設計中會耗費極大的暫存器面積，並引入極高的運算延遲。
**本設計硬體優勢：**
  我們在內部**僅維護一個大小為 $K$ 的暫存器陣列 `top_k`**（並保持由大到小排序）。當每筆有效資料（`valid == 1`）進來時，利用 Verilog 的**非阻塞賦值（Non-blocking Assignment, `<=`）之並行硬體特性**，在同一個 Clock 上升沿將新資料與 $K$ 個格子同時比較並進行骨牌式的移位與插入：
  $$\text{New Data} \rightarrow \text{Parallel Comparison} \rightarrow \text{Simultaneous Shifting} \rightarrow \text{Top-K Updated in 1 Cycle}$$
  這將空間複雜度從 $O(N)$ 降到 $O(K)$，且無須任何後處理時間，實現**零排序延遲**。



### 📡 2. 動態參數鎖存機制（Parameter Latching）
* **時序挑戰：** 測試平台（Testbench）在啟動時（`start == 1`）會給予完整的參數 `count`（例如 `3f` / $63$），但隨後為了節能或協定規範，會將外部 `count` 埠降回 `0`。如果 FSM 在 `PROC` 運算狀態中直接與輸入埠 `count` 比對，將導致邊界條件永遠無法對齊。
* **解決方案：** 我們設計了 `reg_count` 暫存器。在 `IDLE` 狀態偵測到 `start == 1` 的那一拍上升沿，**立刻將外部 `count` 鎖存至 `reg_count` 內部**。整個運算過程皆與穩定的 `reg_count` 比對，完全阻絕外部動態輸入訊號隨時間消逝而造成的邏輯失效。


### 🔄 3. 狀態機（FSM）運作流程詳細拆解

本系統使用一個穩健的三狀態有限狀態機（3-State FSM）來進行資料流調度：

```text
       +=============+
       |    IDLE     |  <-------------------------+
       +=============+                            |
              |                                   |
              |  start == 1                       |
              v (Latch count to reg_count,        |
       +=============+   Clear top_k)             |
       |    PROC     |                            |
       +=============+                            |
              |                                   |
              |  input_count == reg_count         |
              v (Process finished)                |
       +=============+                            |
       |    DONE     |  --------------------------+
       +=============+  (Output finish pulse &
                         kth_largest for 1 cycle)