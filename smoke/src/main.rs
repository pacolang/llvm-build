use std::ffi::{CStr, CString};
use std::ptr::null_mut;

use llvm_sys::core::*;
use llvm_sys::target::*;
use llvm_sys::target_machine::*;

fn main() {
    unsafe {
        LLVM_InitializeAllTargetInfos();
        LLVM_InitializeAllTargets();
        LLVM_InitializeAllTargetMCs();
        LLVM_InitializeAllAsmPrinters();
        let context = LLVMContextCreate();
        let module = LLVMModuleCreateWithNameInContext(c"smoke".as_ptr(), context);
        let function_type = LLVMFunctionType(LLVMInt32TypeInContext(context), null_mut(), 0, 0);
        let function = LLVMAddFunction(module, c"answer".as_ptr(), function_type);
        let builder = LLVMCreateBuilderInContext(context);
        LLVMPositionBuilderAtEnd(builder, LLVMAppendBasicBlockInContext(context, function, c"entry".as_ptr()));
        LLVMBuildRet(builder, LLVMConstInt(LLVMInt32TypeInContext(context), 42, 0));
        for triple in ["x86_64-unknown-linux-gnu", "aarch64-unknown-linux-gnu", "x86_64-pc-windows-msvc", "aarch64-apple-macosx11.0.0"] {
            let triple = CString::new(triple).unwrap();
            let mut target = null_mut();
            let mut error = null_mut();
            if LLVMGetTargetFromTriple(triple.as_ptr(), &mut target, &mut error) != 0 {
                panic!("{:?}: {}", triple, CStr::from_ptr(error).to_string_lossy());
            }
            let machine = LLVMCreateTargetMachine(
                target,
                triple.as_ptr(),
                c"generic".as_ptr(),
                c"".as_ptr(),
                LLVMCodeGenOptLevel::LLVMCodeGenLevelAggressive,
                LLVMRelocMode::LLVMRelocPIC,
                LLVMCodeModel::LLVMCodeModelDefault,
            );
            let mut buffer = null_mut();
            if LLVMTargetMachineEmitToMemoryBuffer(machine, module, LLVMCodeGenFileType::LLVMObjectFile, &mut error, &mut buffer) != 0 {
                panic!("{:?}: {}", triple, CStr::from_ptr(error).to_string_lossy());
            }
            assert!(LLVMGetBufferSize(buffer) > 0);
            LLVMDisposeMemoryBuffer(buffer);
            LLVMDisposeTargetMachine(machine);
        }
        let (mut major, mut minor, mut patch) = (0, 0, 0);
        LLVMGetVersion(&mut major, &mut minor, &mut patch);
        println!("LLVM {major}.{minor}.{patch}: emitted objects for x86_64 and aarch64 (ELF, COFF, Mach-O)");
    }
}
