import json
import asyncio
from fastapi import BackgroundTasks, HTTPException

# Import trực tiếp các instance Manager duy nhất từ hệ thống của bạn
from app.managers.stepper_manager import stepper_manager
from app.managers.servo_manager import servo_manager
from app.managers.led_manager import led_route_manager
from app.managers.gas_manager import gas_manager
from app.managers.dht_manager import dht_manager
from app.managers.dc_motor_manager import dc_motor_manager 

print("==================================================")
print("⚙️ MATRIX NLP SMART HOME CHUẨN HÓA TOÀN DIỆN V4:")
print("💡 Ưu tiên vị trí được nhắc tới trước khi tự động fallback phòng khách.")
print("==================================================")


async def execute_smart_scenarios(scenario: str, background_tasks: BackgroundTasks) -> str:
    """
    Hàm xử lý các kịch bản phối hợp thiết bị phức tạp (Ngữ cảnh thông minh).
    """
    try:
        if scenario == "go_out":
            rooms = led_route_manager.device_manager.leds.keys()
            for room in rooms:
                led_route_manager.control_room_led(room_name=room, status=False)
            try: await dc_motor_manager.execute_close()
            except Exception: pass
            try: stepper_manager.control_door_action(action="close", times=2, background_tasks=background_tasks)
            except Exception: pass
            try:
                servo_manager.close_door(door_type="front")
                servo_manager.close_door(door_type="back")
            except Exception: pass
            return "Kịch bản 'Ra Ngoài' kích hoạt: Đã tắt toàn bộ hệ thống đèn và tiến hành đóng tất cả các cửa (cửa trượt, cửa nhà xe, cửa phòng). Chúc bạn một ngày tốt lành!"

        elif scenario == "go_to_sleep":
            rooms = led_route_manager.device_manager.leds.keys()
            for room in rooms:
                led_route_manager.control_room_led(room_name=room, status=False)
            try: await dc_motor_manager.execute_close()
            except Exception: pass
            return "Kịch bản 'Đi Ngủ' kích hoạt: Đã khóa chặt cửa trượt và tắt toàn bộ hệ thống đèn. Chúc bạn ngủ ngon!"

        elif scenario == "welcome_home":
            led_route_manager.control_room_led(room_name="living-room", status=True)
            led_route_manager.control_room_led(room_name="dining", status=True)
            try: await dc_motor_manager.execute_open()
            except Exception: pass
            return "Chào mừng bạn đã về nhà! Tôi đã mở cửa trượt và bật sẵn đèn phòng khách."

    except Exception as e:
        print(f"❌ Lỗi thực thi kịch bản ngữ cảnh: {str(e)}")
        return "Gặp trục trặc phần cứng khi cố gắng thiết lập kịch bản thông minh."
    return "Không tìm thấy kịch bản phù hợp."


async def execute_hardware_action(device: str, scope: str, state: str, user_input: str, background_tasks: BackgroundTasks) -> str:
    """
    Ánh xạ quyết định từ bộ lọc từ khóa thành lệnh gọi trực tiếp các MANAGER phần cứng.
    Đảm bảo Đèn nhận 'bật'/'tắt', Cửa nhận 'mở'/'đóng'.
    """
    user_input_lower = user_input.lower()

    # ========================================================
    # 📑 TRƯỜNG HỢP 1: TRUY VẤN XEM TRẠNG THÁI HOẶC ĐỌC CẢM BIẾN
    # ========================================================
    if state == "xem":
        if device == "cảm biến dht":
            dht_data = dht_manager.get_sensor_data()
            return f"Nhiệt độ hiện tại đo được là {dht_data.get('temp', 25)}°C và độ ẩm là {dht_data.get('humi', 60)}%."
        elif device == "cảm biến gas":
            gas_data = gas_manager.get_current_gas_data()
            val = float(gas_data.get('value', 1.0))
            return "Cảnh báo nguy hiểm! Phát hiện rò rỉ khí gas!" if val == 0.0 else "Chỉ số khí gas bình thường, an toàn."
        elif device == "cửa gara":
            res = stepper_manager.get_door_state()
            status = res.get("state", "unknown")
            vi_status = "đang mở" if status in ["open", "opened"] else "đang đóng" if status in ["closed", "close"] else "đang di chuyển"
            return f"Cửa nhà xe hiện tại {vi_status}."
        elif device == "cửa trượt":
            res = dc_motor_manager.check_motor_status()
            status = res.get("status", "unknown")
            vi_status = "đang mở" if status == "open" else "đang đóng" if status == "closed" else "đang di chuyển"
            return f"Cửa trượt hiện tại {vi_status}."

    # ========================================================
    # 💡 TRƯỜNG HỢP 2: ĐIỀU KHIỂN HỆ THỐNG ĐÈN LED (state == "bật" / "tắt")
    # ========================================================
    if device == "đèn":
        is_on = (state == "bật")
        if scope in ["all", "global"]:
            try:
                rooms = led_route_manager.device_manager.leds.keys()
                for room in rooms: led_route_manager.control_room_led(room_name=room, status=is_on)
                return "Đã thực hiện bật toàn bộ đèn trong ngôi nhà." if is_on else "Đã tắt toàn bộ hệ thống đèn."
            except Exception: return "Gặp sự cố phần cứng khi điều khiển hệ thống đèn."
        else:
            # Mặc định phòng khách nếu tầng AI process hoàn toàn khuyết thông tin vị trí
            target_scope = "living-room"
            vi_room = "phòng khách"
            
            kw_dining = ["bếp", "bếb", "bép", "ăn", "dining", "nhà bếp"]
            kw_bedroom = ["ngủ", "bedroom", "phòng ngủ", "pòng mỡ", "phòng mỡ", "phòng mũ", "pòng ngủ", "pòng mũ"]
            kw_wc = ["vệ sinh", "về sinh", "bệ sinh", "mệ sinh", "wc", "restroom", "tắm", "toa lét", "toilet", "toa let", "nhà tắm"]
            kw_gara = ["nhà xe", "nha xe", "gara", "gá ra", "gà ra", "ga ra", "garage"]
            kw_living = ["khách", "khát", "khác", "living"]

            if any(x in user_input_lower for x in kw_dining):
                target_scope = "dining"
                vi_room = "phòng ăn nhà bếp"
            elif any(x in user_input_lower for x in kw_bedroom):
                target_scope = "bedroom"
                vi_room = "phòng ngủ"
            elif any(x in user_input_lower for x in kw_wc):
                target_scope = "wc"
                vi_room = "nhà vệ sinh"
            elif any(x in user_input_lower for x in kw_gara):
                target_scope = "gara"
                vi_room = "nhà xe"
            elif any(x in user_input_lower for x in kw_living):
                target_scope = "living-room"
                vi_room = "phòng khách"

            try:
                led_route_manager.control_room_led(room_name=target_scope, status=is_on)
                return f"Đã {'bật' if is_on else 'tắt'} đèn tại khu vực {vi_room}."
            except Exception: return f"Không thể điều khiển đèn tại khu vực {vi_room}."            
                
    # ========================================================
    # 🚗 TRƯỜNG HỢP 3: ĐIỀU KHIỂN CỬA NHÀ XE (state == "mở" / "đóng")
    # ========================================================
    if device == "cửa gara":
        action = "open" if state == "mở" else "close"
        try:
            res = stepper_manager.control_door_action(action=action, times=2, background_tasks=background_tasks)
            return f"Hệ thống điều khiển: {res.get('message', 'Đang vận hành cửa nhà xe.')}"
        except Exception: return f"Lệnh {action} cửa nhà xe thất bại."

    # ========================================================
    # ⚡ TRƯỜNG HỢP 4: ĐIỀU KHIỂN CỬA TRƯỢT (state == "mở" / "đóng")
    # ========================================================
    elif device == "cửa trượt":
        action = "open" if state == "mở" else "close"
        try:
            if action == "open":
                await dc_motor_manager.execute_open()
                return "Tôi đang tiến hành mở cửa trượt, vui lòng đợi trong giây lát."
            else:
                await dc_motor_manager.execute_close()
                return "Tôi đang tiến hành đóng cửa trượt, hệ thống sẽ tự động khóa chốt an toàn."
        except HTTPException as http_exc: return f"Không thể thực hiện lệnh. {http_exc.detail}"
        except Exception: return f"Hệ thống cơ khí cửa trượt gặp lỗi khi thực hiện thao tác {action}."

    # ========================================================
    # 🚪 TRƯỜNG HỢP 5: ĐIỀU KHIỂN CỬA PHÒNG NGỦ (state == "mở" / "đóng")
    # ========================================================
    elif device == "cửa trước":
        action = "open" if state == "mở" else "close"
        try:
            if action == "open": servo_manager.open_door(door_type="front", angle=135.0)
            else: servo_manager.close_door(door_type="front")
            return f"Cửa phòng ngủ đã được điều khiển {'mở' if action=='open' else 'đóng'}."
        except Exception: return "Lỗi mạch điều khiển cửa phòng ngủ."
        
    # ========================================================
    # 🚽 TRƯỜNG HỢP 6: ĐIỀU KHIỂN CỬA WC (state == "mở" / "đóng")
    # ========================================================
    elif device == "cửa sau":
        action = "open" if state == "mở" else "close"
        try:
            if action == "open": servo_manager.open_door(door_type="back", angle=135.0)
            else: servo_manager.close_door(door_type="back")
            return f"Cửa phòng vệ sinh đã được điều khiển {'mở' if action=='open' else 'đóng'}."
        except Exception: return "Lỗi mạch điều khiển cửa phòng vệ sinh."

    return "Yêu cầu của bạn đã được ghi nhận nhưng chưa khớp thiết bị phần cứng nào."


async def ai_process_text(user_input: str, background_tasks: BackgroundTasks) -> str:
    """
    Hàm phân tích NLP thủ công (Manual Parsing) siêu tối ưu.
    Trích xuất Hành động và Vị trí độc lập, xử lý dứt điểm lỗi ép sai vị trí mặc định của câu lệnh ngắn.
    """
    user_input_lower = user_input.lower().strip()
    
    # --- BƯỚC 1: KIỂM TRA NGỮ CẢNH THÔNG MINH ---
    if any(kw in user_input_lower for kw in ["ra ngoài", "ra khỏi nhà", "đi làm", "đi học", "tạm biệt", "vắng nhà"]):
        return await execute_smart_scenarios("go_out", background_tasks)
    elif any(kw in user_input_lower for kw in ["đi ngủ", "chúc ngủ ngon", "lên giường"]):
        return await execute_smart_scenarios("go_to_sleep", background_tasks)
    elif any(kw in user_input_lower for kw in ["về rồi", "về đến nhà", "về nhà"]):
        return await execute_smart_scenarios("welcome_home", background_tasks)

    # --- BƯỚC 2: PHÂN TÁCH BIẾN THỂ TỪ KHÓA VỊ TRÍ ---
    words_gara = ["nhà xe", "nha xe", "gara", "gá ra", "gà ra", "ga ra", "garage"]
    words_wc = ["vệ sinh", "về sinh", "bệ sinh", "mệ sinh", "wc", "restroom", "tắm", "toa lét", "toilet", "toa let", "nhà tắm"]
    words_bedroom = ["phòng ngủ", "ngủ", "bedroom", "pòng mỡ", "phòng mỡ", "phòng mũ", "pòng ngủ", "pòng mũ"]
    words_dining = ["bếp", "bếb", "bép", "ăn", "dining", "nhà bếp"]
    words_living = ["khách", "khát", "khác", "living"]

    current_location = None
    if any(x in user_input_lower for x in words_gara): current_location = "gara"
    elif any(x in user_input_lower for x in words_wc): current_location = "wc"
    elif any(x in user_input_lower for x in words_bedroom): current_location = "bedroom"
    elif any(x in user_input_lower for x in words_dining): current_location = "dining"
    elif any(x in user_input_lower for x in words_living): current_location = "living"
    
    # SỬA LỖI: Chỉ fallback về phòng khách khi câu lệnh HOÀN TOÀN KHÔNG CHỨA bất kỳ từ khóa phòng nào khác
    if current_location is None and any(kw in user_input_lower for kw in ["tối quá", "tối thế", "chói quá"]): 
        current_location = "living"

    # --- BƯỚC 3: PHÂN TÁCH Ý ĐỊNH HÀNH ĐỘNG THUẦN TÚY (INTENT) ---
    kw_open_physical = ["mở", "mỡ", "mo", "kéo lên", "mở ra", "kênh"]
    kw_close_physical = ["đóng", "khóa", "sập", "hạ xuống", "khóa lại"]
    kw_light_on = ["bật", "thắp", "tối quá", "tối thế", "đêm", "đẻn", "đèng", "sáng"]
    kw_light_off = ["tắt", "chói"]
    kw_action_view = ["mấy", "bao nhiêu", "kiểm tra", "xem", "trạng thái", "đang đóng hay mở", "chưa", "thế nào"]

    intent_action = None
    if any(kw in user_input_lower for kw in kw_action_view):
        intent_action = "xem"
    elif any(kw in user_input_lower for kw in kw_light_on):
        intent_action = "on"
    elif any(kw in user_input_lower for kw in kw_light_off):
        intent_action = "off"
    elif any(kw in user_input_lower for kw in kw_open_physical):
        intent_action = "open"
    elif any(kw in user_input_lower for kw in kw_close_physical):
        intent_action = "close"

    # --- BƯỚC 4: MATRIX ÁNH XẠ THIẾT BỊ HOÀN HẢO ---
    device = None
    scope = "single"
    state = "mở"

    # 1. Ưu tiên tuyệt đối cho CẢM BIẾN
    if any(x in user_input_lower for x in ["nhiệt độ", "độ ẩm", "nóng", "lạnh", "dht"]):
        device = "cảm biến dht"
        state = "xem"
        return await execute_hardware_action(device, scope, state, user_input, background_tasks)
    elif any(x in user_input_lower for x in ["ga", "khí gas", "rò rỉ", "mùi"]):
        device = "cảm biến gas"
        state = "xem"
        return await execute_hardware_action(device, scope, state, user_input, background_tasks)

    # 2. KIỂM TRA TỪ KHÓA THỰC THỂ CỨNG RÕ RÀNG (Nếu user nói rõ từ "cửa", "cổng")
    has_door_keyword = any(x in user_input_lower for x in ["cửa", "cổng", "kênh", "của", "cữa"])

    if has_door_keyword:
        if current_location == "gara": device = "cửa gara"
        elif current_location == "bedroom": device = "cửa trước"
        elif current_location == "wc": device = "cửa sau"
        else: device = "cửa trượt"
        
        # Ánh xạ hành động cho cửa
        if intent_action in ["open", "on"]: state = "mở"
        elif intent_action in ["close", "off"]: state = "đóng"
        else: state = "xem"

    # 3. NẾU KHÔNG CÓ TỪ KHÓA "CỬA", ĐỊNH TUYẾN THEO HÀNH ĐỘNG CHUẨN HÓA MỚI
    else:
        if intent_action in ["on", "off"]:
            device = "đèn"
            state = "bật" if intent_action == "on" else "tắt"
            # Trích xuất phạm vi toàn cục
            if any(x in user_input_lower for x in ["toàn bộ", "tất cả", "hết", "mọi", "toàn nhà"]):
                scope = "all"
        elif intent_action in ["open", "close"]:
            if current_location == "gara": device = "cửa gara"
            elif current_location == "bedroom": device = "cửa trước"
            elif current_location == "wc": device = "cửa sau"
            else: device = "cửa trượt"
            state = "mở" if intent_action == "open" else "đóng"
        elif intent_action == "xem":
            state = "xem"
            if current_location == "gara": device = "cửa gara"
            elif current_location is None: device = "cửa trượt"
            else: device = "đèn"
        else:
            # Fallback định tuyến an toàn theo vị trí
            if current_location in ["bedroom", "gara", "wc", "dining", "living"]:
                device = "đèn"
                state = "bật"
            else:
                return "Yêu cầu không rõ ràng, bạn muốn điều khiển cửa hay đèn bấm/nói lại giúp tôi nhé."

    # --- BƯỚC 5: THỰC THI PHẦN CỨNG BẤT ĐỒNG BỘ ---
    final_voice_reply = await execute_hardware_action(
        device=device, 
        scope=scope, 
        state=state, 
        user_input=user_input, 
        background_tasks=background_tasks
    )
    
    return final_voice_reply
