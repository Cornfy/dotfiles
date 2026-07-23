import os
import sys
import argparse
import subprocess
import shutil
from pathlib import Path
from PIL import Image

# === 导入并配置警告拦截器（消除 torch.meshgrid 带来的无关废弃警示） ===
import warnings
warnings.filterwarnings("ignore", category=UserWarning, message=".*torch.meshgrid.*")
# ==================================================================

import torch
import torchvision.transforms as T
from spandrel import ModelLoader

from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.progress import Progress, BarColumn, TextColumn, TimeElapsedColumn, MofNCompleteColumn

console = Console()

# ==============================================================================
# 1. 环境与配置检测模块
# ==============================================================================

def parse_arguments():
    """解析命令行参数，集成精美的模型选择指南"""
    usage_epilog = """
使用示例 (Examples):
  # 获取帮助
  uv run process.py --help

  # 测试模式
  uv run process.py --drun

  # 快速开始（默认使用 Nomos8kDAT 算法，默认放大 4 倍）
  uv run process.py

  # 指定模型（如：动漫图推荐使用 AnimeSharp 算法）
  uv run process.py --model 4x-AnimeSharp.pth

  # 自定义参数（如指定模型，放大 2 倍输出，设置切块大小为 1024）
  uv run process.py --model 4x-AnimeSharp.pth --scale 2.0 --tile 1024

  # 纯净超分模式（跳过所有体积压缩、元数据克隆与物理归档后处理）
  uv run process.py --skip_post
"""

    parser = argparse.ArgumentParser(
        description="🔧 Transcale - Transformer 图像超分与资产管理工具 (Modularized SR Pipeline)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=usage_epilog
    )
    parser.add_argument('--input', type=str, default='./Input', help='输入图像目录')
    parser.add_argument('--output', type=str, default='./Optimized', help='输出图像目录')
    parser.add_argument('--model', type=str, default='4x-Nomos8kDAT.pth', help='模型文件名或绝对路径')
    parser.add_argument('--tile', type=int, default=512, help='分块窗口大小')
    parser.add_argument('--scale', type=float, default=4.0, help='目标输出倍率')
    parser.add_argument('--skip_post', action='store_true', help='跳过所有后处理步骤 (包括体积优化、元数据克隆、时间戳同步与归档)')
    parser.add_argument('--drun', action='store_true', help='开启演练模式')

    # 如果用户运行的是 -h 或 --help，在系统打印完基础参数后，强行追加精美的模型指南面板
    if len(sys.argv) > 1 and sys.argv[1] in ('-h', '--help'):
        parser.print_help()
        print("\n" + "="*80)

        # 构建 Rich 格式的模型指南面板
        guide_text = (
            "[bold magenta]💡 针对不同场景的 AI 模型权重选择建议 (Model Selection Guide):[/bold magenta]\n\n"
            "  [bold cyan]1. 4x-AnimeSharp.pth[/bold cyan] (二次元线条锐化与渐变保留的平衡神作)\n"
            "     [dim]• 特点：由经典插值演变，专门针对动漫边缘优化，既能让线条干净，又不易造成渐变色块断层。[/dim]\n"
            "     [yellow]👉 推荐场景：赛璐璐画风、平涂色块、高对比度二次元插画。[/yellow]\n\n"
            "  [bold cyan]2. 4x_fatal_Anime.pth[/bold cyan] (手绘/厚涂细节守护者，极力避免塑料抹平感)\n"
            "     [dim]• 特点：二次元圈非常著名的模型，擅长去除画面杂质并还原纸纹、水彩笔触质感，拒绝AI塑料涂抹味。[/dim]\n"
            "     [yellow]👉 推荐场景：手绘风二次元插画、水彩/油画风厚涂动漫、日系复古漫画。[/yellow]\n\n"
            "  [bold cyan]3. 4x-Swin2SR-Compressed.pth[/bold cyan] (Swin2SR 官方去伪影/去低保真噪声模型)\n"
            "     [dim]• 特点：基于 SwinV2 Transformer 架构，专门针对重度 JPEG 压缩或网图缩放导致的拉丝条纹、网格进行强力修复。[/dim]\n"
            "     [yellow]👉 推荐场景：网络低清老图修复、表情包除噪、重度压缩过的动漫截图。[/yellow]\n\n"
            "  [bold cyan]4. 4x-Nomos8kDAT.pth[/bold cyan] (Dual Attention Transformer 真实照片复原模型)\n"
            "     [dim]• 特点：针对 8000 张真实世界带噪点和模糊的照片训练，去噪和细节还原极度自然，无动漫模型的矢量感。[/dim]\n"
            "     [yellow]👉 推荐场景：日常手机照片、自然风景、三次元人像、微距静物。[/yellow]\n"
        )
        console.print(Panel(guide_text, title="[bold magenta]🧠 核心超分权重导览[/bold magenta]", border_style="magenta"))
        sys.exit(0)

    return parser.parse_args()


def detect_device():
    """动态嗅探运行硬件环境"""
    if torch.cuda.is_available():
        device = torch.device("cuda")
        device_name = torch.cuda.get_device_name(0)
        use_gpu = True
    elif hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
        device = torch.device("mps")
        device_name = "Apple Silicon macOS (MPS)"
        use_gpu = True
    else:
        device = torch.device("cpu")
        device_name = "CPU 向量计算加速"
        use_gpu = False
    return device, device_name, use_gpu


def check_system_dependencies(skip_post):
    """
    验证外部命令行工具链可用性。
    采用“优雅降级”设计：缺失 oxipng 或 exiftool 时仅产生提示，安全跳过对应后处理，绝不中断核心超分流程。
    如果显式指定了 --skip_post，则直接跳过依赖扫描。
    """
    if skip_post:
        return False, False, False

    has_exiftool = bool(shutil.which("exiftool"))
    has_oxipng = bool(shutil.which("oxipng"))
    has_sorter = bool(shutil.which("media-sorter"))

    missing_helpers = []
    if not has_exiftool:
        missing_helpers.append("[yellow]exiftool[/yellow] (负责克隆原图 ICC 配置文件与 EXIF 资产数据)")
    if not has_oxipng:
        missing_helpers.append("[yellow]oxipng[/yellow] (基于 Rust 的无损 PNG 极限压缩器)")

    # 软性警告提示，不执行 sys.exit
    if missing_helpers:
        warn_msg = "[yellow]⚠️ 提示：检测到部分外围后处理底层工具缺失。[/yellow]\n\n"
        warn_msg += "为了保证核心超分逻辑正常运行，程序已[bold green]自动降级[/bold green]并准备跳过对应的后处理步骤：\n"
        for item in missing_helpers:
            warn_msg += f"  - {item}\n"
        warn_msg += "\n[cyan]💡 如果需要完整的画质优化与数据保存，请使用包管理器进行安装。[/cyan]\n"
        warn_msg += "  - Linux (Arch) 用户:  [bold green]sudo pacman -S exiftool oxipng[/bold green]\n"
        warn_msg += "  - macOS 用户:          [bold green]brew install exiftool oxipng[/bold green]\n"

        console.print(Panel(warn_msg, title="[bold yellow]后处理工具缺失 (安全降级)[/bold yellow]", border_style="yellow"))
        print()

    if not has_sorter:
        console.print("[yellow]⚠️  提示: 未在系统中检测到 'media-sorter'。最终的资产固化归档步骤将被安全跳过。[/yellow]\n")

    return has_exiftool, has_oxipng, has_sorter


def resolve_model_path(model_arg):
    """定位或校验神经网络权重路径"""
    if os.path.exists(model_arg):
        return model_arg

    fallback_path = os.path.join("./.pth_models", model_arg)
    if os.path.exists(fallback_path):
        return fallback_path

    console.print(Panel(
        f"[red]❌ 核心权重缺失: {model_arg}[/red]\n\n"
        f"[yellow]请将权重放入 ./.pth_models/ 目录或指定正确的 --model 路径。[/yellow]", 
        title="[bold red]错误[/bold red]",
        border_style="red"
    ))
    sys.exit(1)


# ==============================================================================
# 2. UI 表现模块
# ==============================================================================

def print_dashboard(args, device_name, use_gpu, has_exiftool, has_oxipng, has_sorter, model_path):
    """打印控制台面板状态表"""
    table = Table(title="🎛️ Transformer Super-Resolution Pipeline", title_style="bold magenta")
    table.add_column("配置项", style="cyan", no_wrap=True)
    table.add_column("状态 / 物理参数", style="green")
    
    run_mode_str = "[bold yellow]🧪 DRY-RUN (模拟空转演练)[/bold yellow]" if args.drun else "[bold green]🚀 PRODUCTION (生产环境运行)[/bold green]"
    table.add_row("运行模式", run_mode_str)
    table.add_row("计算设备", f"{'🔥 GPU 加速' if use_gpu else '🧠 PURE CPU'} ({device_name})")
    table.add_row("核心权重", os.path.basename(model_path))
    table.add_row("矩阵与重叠", f"Tile: {args.tile}px | Overlap: 64px")
    table.add_row("目标倍率", f"{args.scale}x (动态降采样)" if args.scale != 4.0 else "4.0x (原生直出)")
    
    # 根据是否开启 --skip_post，自适应展示工具链状态
    if args.skip_post:
        tools_str = "[yellow]⚠️ 已跳过全部后处理 (Skip Post Active)[/yellow]"
    else:
        tools_str = f"ExifTool: {'✅' if has_exiftool else '❌'} | Oxipng: {'✅' if has_oxipng else '❌'} | Media-Sorter: {'✅' if has_sorter else '⚠️(不可用)'}"
        
    table.add_row("环境工具链", tools_str)
    console.print(table)
    print()


# ==============================================================================
# 3. 数据输入/输出处理模块
# ==============================================================================

def get_input_images(input_dir):
    """跨平台扫描指定目录下的合规图像资产"""
    input_path_obj = Path(input_dir)
    valid_exts = {'.png', '.jpg', '.jpeg', '.webp', '.gif'}
    if not input_path_obj.exists():
        return []
    return [str(p) for p in input_path_obj.iterdir() if p.suffix.lower() in valid_exts]


def load_and_preprocess_image(img_path):
    """读取图像并进行色彩空间与透明通道预标准化"""
    raw_img = Image.open(img_path)
    w, h = raw_img.size

    if raw_img.mode in ('RGBA', 'LA') or (raw_img.mode == 'P' and 'transparency' in raw_img.info):
        # 混合透明通道至纯白背景板以防止边缘产生杂色黑框
        bg = Image.new("RGB", raw_img.size, (255, 255, 255))
        bg.paste(raw_img, mask=raw_img.convert("RGBA").split()[3])
        img = bg
    else:
        img = raw_img.convert('RGB')
    return img, w, h


def get_tile_coords(full_size, tile_size, stride):
    """生成轴向唯一的切片起始坐标"""
    if full_size <= tile_size:
        return [0]
    coords = []
    pos = 0
    while pos + tile_size < full_size:
        coords.append(pos)
        pos += stride
    if coords[-1] != full_size - tile_size:
        coords.append(full_size - tile_size)
    return coords


# ==============================================================================
# 4. 核心计算（超分推理）模块
# ==============================================================================

def load_sr_model(model_path, device):
    """载入并编译/准备 Spandrel 超分模型"""
    with console.status("[bold yellow]📦 正在解析网络结构...[/bold yellow]"):
        model = ModelLoader().load_from_file(model_path)
        model.to(device)
        model.eval()
    return model


def run_tiled_inference(model, img, device, tile_size, stride, native_scale, x_coords, y_coords, native_out_w, native_out_h):
    """
    分块矩阵重叠推理核心核心算法。
    将运算画布暂存于 CPU，单块推理于指定的加速硬件，保障宿主系统的运行稳定性。
    """
    w, h = img.size
    in_tensor = T.ToTensor()(img).unsqueeze(0).to(device)
    output_tensor = torch.zeros((1, 3, native_out_h, native_out_w), device="cpu")
    output_scan_mask = torch.zeros((1, 1, native_out_h, native_out_w), device="cpu")
    total_tiles = len(x_coords) * len(y_coords)

    with torch.no_grad():
        with Progress(
            TextColumn("    [magenta]└─ 🧠 张量计算中...[/magenta]"),
            BarColumn(bar_width=40, style="black", complete_style="green"),
            MofNCompleteColumn(),
            TimeElapsedColumn(),
            console=console
        ) as progress:
            tile_task = progress.add_task("矩阵", total=total_tiles)

            for y_start in y_coords:
                for x_start in x_coords:
                    y_end = min(y_start + tile_size, h)
                    x_end = min(x_start + tile_size, w)

                    crop_patch = in_tensor[:, :, y_start:y_end, x_start:x_end]

                    try:
                        output_patch = model(crop_patch)
                    except Exception:
                        output_patch = model.model(crop_patch) if hasattr(model, 'model') else model.__call__(crop_patch)

                    # 转移至物理内存以释放显存
                    output_patch = output_patch.cpu()

                    oy_start, oy_end = y_start * native_scale, y_end * native_scale
                    ox_start, ox_end = x_start * native_scale, x_end * native_scale

                    output_tensor[:, :, oy_start:oy_end, ox_start:ox_end] += output_patch
                    output_scan_mask[:, :, oy_start:oy_end, ox_start:ox_end] += 1.0

                    progress.advance(tile_task)

    # 归一化重叠矩阵并导出
    output_tensor /= output_scan_mask
    output_tensor = output_tensor.squeeze(0).clamp(0, 1)
    return T.ToPILImage()(output_tensor)


# ==============================================================================
# 5. 单图业务编排管道
# ==============================================================================

def process_single_image(img_path, idx, total_images, model, device, args, native_scale, has_exiftool, has_oxipng):
    """单张图像全流程生命周期编排（加载、推演、存储、后处理）"""
    img_name = os.path.basename(img_path)
    console.print(f"[bold blue]🎬 [{idx}/{total_images}] 正在处理: {img_name}[/bold blue]")

    img, w, h = load_and_preprocess_image(img_path)

    tile_size = args.tile
    overlap = 64
    stride = tile_size - overlap

    x_coords = get_tile_coords(w, tile_size, stride)
    y_coords = get_tile_coords(h, tile_size, stride)
    total_tiles = len(x_coords) * len(y_coords)

    native_out_w, native_out_h = w * native_scale, h * native_scale
    target_w, target_h = int(w * args.scale), int(h * args.scale)

    console.print(f"    [dim cyan]├─ 📊 图像几何数据: 原始 {w}x{h} -> 原生超分 {native_out_w}x{native_out_h} | 切片数: {total_tiles}[/dim cyan]")

    # 确定输出格式与物理落地路径
    out_name = f"opt_{img_name}"
    if out_name.lower().endswith(('.jpg', '.jpeg', '.webp')):
        out_name = os.path.splitext(out_name)[0] + '.png'
    target_path = os.path.join(args.output, out_name)

    # Dry-Run 分支拦截
    if args.drun:
        if args.scale != native_scale:
            console.print(f"    [dim yellow]├─ 📐 [Dry-Run] 预估重采样: {native_out_w}x{native_out_h} -> Lanczos 至 {target_w}x{target_h}[/dim yellow]")
        if not args.skip_post:
            run_post_process(img_path, target_path, console, has_exiftool, has_oxipng, dry_run=True)
        console.print(f"    [bold yellow]└─ 🧪 [Dry-Run] 演练通过 -> 预期物理路径: {target_path}[/bold yellow]\n")
        return

    # Tiled 计算
    out_img = run_tiled_inference(
        model, img, device, tile_size, stride, native_scale, 
        x_coords, y_coords, native_out_w, native_out_h
    )

    if device.type == "cuda":
        torch.cuda.empty_cache()

    # 重采样缩放
    if args.scale != native_scale:
        console.print(f"    [dim cyan]├─ 📐 重采样 ({native_scale}x -> {args.scale}x): {target_w}x{target_h}[/dim cyan]")
        out_img = out_img.resize((target_w, target_h), Image.Resampling.LANCZOS)

    out_img.save(target_path, format="PNG")

    # 物理后处理管道 (如果用户指定了 --skip_post 则整体跳过)
    if not args.skip_post:
        run_post_process(img_path, target_path, console, has_exiftool, has_oxipng, dry_run=False)
    console.print(f"    [bold green]└─ ✨ 已保存 -> {target_path}[/bold green]\n")


# ==============================================================================
# 6. 归档后处理模块
# ==============================================================================

def run_post_process(ref_path, target_path, console, has_exiftool, has_oxipng, dry_run=False):
    """外围数据层优化与写入（先压缩，后写入元数据，确保数据安全）"""
    # 1. 无损压缩优化 PNG 体积
    if has_oxipng:
        if dry_run:
            console.print("    [dim yellow]├─ 🧪 [Dry-Run] 预估执行: Oxipng 无损体积压缩[/dim yellow]")
        else:
            console.print("    [dim cyan]├─ 📦 优化体积 (Oxipng)...[/dim cyan]")
            try:
                subprocess.run([
                    "oxipng", "-o", "4", "--strip", "safe", target_path
                ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except Exception as e:
                console.print(f"    [red]⚠️ Oxipng 执行异常: {e}[/red]")

    # 2. 原图 ICC 色彩配置文件与 EXIF 信息物理重写入
    if has_exiftool:
        if dry_run:
            console.print("    [dim yellow]├─ 🧪 [Dry-Run] 预估执行: ExifTool 写入 ICC/EXIF[/dim yellow]")
        else:
            console.print("    [dim cyan]├─ 🏷️  注入元数据 (ExifTool ICC/EXIF Clone)...[/dim cyan]")
            try:
                subprocess.run([
                    "exiftool", "-TagsFromFile", ref_path, 
                    "-all:all", "-icc_profile", "-overwrite_original", target_path
                ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except Exception as e:
                console.print(f"    [red]⚠️ ExifTool 执行异常: {e}[/red]")

    # 3. 物理级时间戳同步 (mtime)
    if dry_run:
        console.print("    [dim yellow]├─ 🧪 [Dry-Run] 预估执行: 同步物理时间戳 (mtime)[/dim yellow]")
    else:
        console.print("    [dim cyan]├─ ⏱️  同步时间戳 (mtime sync)...[/dim cyan]")
        try:
            ref_stat = os.stat(ref_path)
            os.utime(target_path, (ref_stat.st_atime, ref_stat.st_mtime))
        except Exception as e:
            console.print(f"    [red]⚠️ 时间戳同步失败: {e}[/red]")


def finalize_assets(output_dir, skip_post, has_sorter, is_drun):
    """终期固化物理归档逻辑（可选）"""
    # 如果用户显式跳过所有后处理，或者系统未安装 media-sorter，直接返回
    if skip_post or not has_sorter:
        return

    if is_drun:
        console.print(f"[bold yellow]🧪 [Dry-Run] 预估执行: media-sorter 归档目录 {output_dir}[/bold yellow]")
    else:
        with console.status(f"[bold magenta]📁 正在启动媒体库归档...[/bold magenta]"):
            try:
                subprocess.run([
                    "media-sorter", "-no-backup", "-yes", "-dir", output_dir
                ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except Exception as e:
                console.print(f"[red]⚠️ media-sorter 归档运行异常: {e}[/red]")
        console.print("[bold green]🎯 所有图像处理与归档固化任务完成。[/bold green]")


# ==============================================================================
# 7. 控制枢纽
# ==============================================================================

def main():
    args = parse_arguments()

    # 依赖项基础校验 (移除了 is_drun 传参，实现完全非阻塞设计)
    has_exiftool, has_oxipng, has_sorter = check_system_dependencies(args.skip_post)

    # 强制基础输出与输入空间落盘
    os.makedirs(args.input, exist_ok=True)
    os.makedirs(args.output, exist_ok=True)

    model_path = resolve_model_path(args.model)
    device, device_name, use_gpu = detect_device()

    # 状态面板仪表盘打印
    print_dashboard(args, device_name, use_gpu, has_exiftool, has_oxipng, has_sorter, model_path)

    # 装载神经网络
    model = load_sr_model(model_path, device)

    # 获取资产列表
    images = get_input_images(args.input)
    if not images:
        console.print(Panel(f"[yellow]⚠️  输入目录 {args.input} 内暂未检测到有效图像资产。[/yellow]", title="[bold yellow]提示[/bold yellow]", border_style="yellow"))
        return

    native_scale = getattr(model.architecture, "scale", 4)

    # 执行业务流程编排
    for idx, img_path in enumerate(images, 1):
        process_single_image(
            img_path, idx, len(images), model, device, args, 
            native_scale, has_exiftool, has_oxipng
        )

    # 执行媒体目录整理
    finalize_assets(args.output, args.skip_post, has_sorter, args.drun)


if __name__ == '__main__':
    main()
